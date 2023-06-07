local C = require('erde.constants')
local utils = require('erde.utils')

-- Foward declare
local tokenize_token

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

-- The source text to tokenize (erde)
local text = ''

-- The current character we are processing
local current_char = ''

-- The index of `current_char` in `text`
local current_char_index = 1

-- The line number of `current_char` in `text`
local current_line = 1

-- `local text` as an array of tokens
local tokens = {}

-- Equivalent to `#tokens`, but selfd separately purely as optimization.
local num_tokens = 0

-- Table for looking up the line number for any token.
--
-- For example, `token_lines[3]` gives the line number of the third token.
local token_lines = {}

-- The name to use when referencing `store.text`. Used for error reporting.
local source_name = ''

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function peek(n)
  return text:sub(current_char_index, current_char_index + n - 1)
end

local function look_ahead(n)
  return text:sub(current_char_index + n, current_char_index + n)
end

local function throw(message, line)
  -- Use error level 0 since we already include `source_name`
  error(('%s:%d: %s'):format(source_name, line or current_line, message), 0)
end

local function commit(token, line)
  num_tokens = num_tokens + 1
  tokens[num_tokens] = token
  token_lines[num_tokens] = line or current_line
end

local function consume(n)
  n = n or 1
  local consumed = n == 1 and current_char or peek(n)
  current_char_index = current_char_index + n
  current_char = text:sub(current_char_index, current_char_index)
  return consumed
end

-- -----------------------------------------------------------------------------
-- Partials
--
-- These functions do not commit anything, and instead have non-trivial returns.
-- -----------------------------------------------------------------------------

local function newline()
  current_line = current_line + 1
  return consume()
end

local function escape_sequence()
  if C.STANDARD_ESCAPE_CHARS[current_char] then
    return consume()
  elseif C.DIGIT[current_char] then
    return consume()
  elseif current_char == 'z' then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      throw('escape sequence \\z not compatible w/ lua targets 5.1, 5.1+')
    end

    return consume()
  elseif current_char == 'x' then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      throw('escape sequence \\xXX not compatible w/ lua targets 5.1, 5.1+')
    end

    if not C.HEX[look_ahead(1)] or not C.HEX[look_ahead(2)] then
      throw('escape sequence \\xXX must use exactly 2 hex characters')
    end

    return consume(3)
  elseif current_char == 'u' then
    local sequence = consume() -- u

    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' or C.LUA_TARGET == '5.2' or C.LUA_TARGET == '5.2+' then
      throw('escape sequence \\u{XXX} not compatible w/ lua targets 5.1, 5.1+, 5.2, 5.2+')
    elseif current_char ~= '{' then
        throw('missing { in escape sequence \\u{XXX}')
    end

    sequence = sequence .. consume()

    if not C.HEX[current_char] then
      throw('missing hex in escape sequence \\u{XXX}')
    end

    while C.HEX[current_char] do
      sequence = sequence .. consume()
    end

    if current_char ~= '}' then
      throw('missing } in escape sequence \\u{XXX}')
    end

    return sequence .. consume()
  else
    throw('invalid escape sequence \\' .. current_char)
  end
end

-- -----------------------------------------------------------------------------
-- Number Tokenizers
-- -----------------------------------------------------------------------------

local function tokenize_binary()
  consume(2) -- 0[bB]
  local token = 0

  if current_char ~= '0' and current_char ~= '1' then
    throw('malformed binary')
  end

  repeat
    token = 2 * token + tonumber(consume())
  until current_char ~= '0' and current_char ~= '1'

  commit(tostring(token))
end

local function tokenize_decimal()
  local token = ''

  while C.DIGIT[current_char] do
    token = token .. consume()
  end

  if current_char == '.' and C.DIGIT[look_ahead(1)] then
    token = token .. consume(2)
    while C.DIGIT[current_char] do
      token = token .. consume()
    end
  end

  if current_char == 'e' or current_char == 'E' then
    token = token .. consume()

    if current_char == '+' or current_char == '-' then
      token = token .. consume()
    end

    if not C.DIGIT[current_char] then
      throw('missing exponent value')
    end

    while C.DIGIT[current_char] do
      token = token .. consume()
    end
  end

  commit(token)
end

local function tokenize_hex()
  consume(2) -- 0[xX]
  local token = 0

  if not C.HEX[current_char] and not (current_char == '.' and C.HEX[look_ahead(1)]) then
    throw('malformed hex')
  end

  while C.HEX[current_char] do
    token = 16 * token + tonumber(consume(), 16)
  end

  if current_char == '.' and C.HEX[look_ahead(1)] then
    consume()
    local counter = 1

    repeat
      token = token + tonumber(consume(), 16) / (16 ^ counter)
      counter = counter + 1
    until not C.HEX[current_char]
  end

  if current_char == 'p' or current_char == 'P' then
    consume()
    local exponent, sign = 0, 1

    if current_char == '+' or current_char == '-' then
      sign = sign * tonumber(consume() .. '1')
    end

    if not C.DIGIT[current_char] then
      throw('missing exponent value')
    end

    repeat
      exponent = 10 * exponent + tonumber(consume())
    until not C.DIGIT[current_char]

    token = token * 2 ^ (sign * exponent)
  end

  commit(tostring(token))
end

-- -----------------------------------------------------------------------------
-- String Tokenizers
-- -----------------------------------------------------------------------------

local function tokenize_interpolation()
  commit(consume()) -- '{'

  -- Keep track of brace depth to differentiate end of interpolation from
  -- nested braces
  local brace_depth, interpolation_line = 0, current_line

  while current_char ~= '}' or brace_depth > 0 do
    if current_char == '{' then
      brace_depth = brace_depth + 1
      commit(consume())
    elseif current_char == '}' then
      brace_depth = brace_depth - 1
      commit(consume())
    elseif current_char == '' then
      throw('unterminated interpolation', interpolation_line)
    else
      tokenize_token()
    end
  end

  commit(consume()) -- '}'
end

local function tokenize_single_quote_string()
  commit(consume()) -- quote

  local content = ''

  while current_char ~= "'" do
    if current_char == '' or current_char == '\n' then
      throw('unterminated string')
    elseif current_char == '\\' then
      content = content .. consume() .. escape_sequence()
    else
      content = content .. consume()
    end
  end

  if content ~= '' then
    commit(content)
  end

  commit(consume()) -- quote
end

local function tokenize_double_quote_string()
  commit(consume()) -- quote

  -- Keep track of content_line in case interpolation has newline
  local content_line, content = current_line, ''

  while current_char ~= '"' do
    if current_char == '' or current_char == '\n' then
      throw('unterminated string')
    elseif current_char == '\\' then
      consume()
      content = content .. ((current_char == '{' or current_char == '}') and consume() or '\\' .. escape_sequence())
    elseif current_char == '{' then
      if content ~= '' then commit(content, content_line) end
      content_line, content = current_line, ''
      tokenize_interpolation(tokenize_token)
    else
      content = content .. consume()
    end
  end

  if content ~= '' then
    commit(content, content_line)
  end

  commit(consume()) -- quote
end

local function tokenize_block_string()
  consume() -- '['

  local equals = ''
  while current_char == '=' do
    equals = equals .. consume()
  end

  if current_char ~= '[' then
    throw('unterminated block string opening', current_line)
  end

  consume() -- '['
  commit('[' .. equals .. '[')

  local close_quote = ']' .. equals .. ']'
  local close_quote_len = #close_quote
  local content_line, content = current_line, ''

  -- Check `current_char ~= ']'` first as slight optimization
  while current_char ~= ']' or peek(close_quote_len) ~= close_quote do
    if current_char == '' then
      throw('unterminated block string', content_line)
    elseif current_char == '\n' then
      content = content .. newline()
    elseif current_char == '\\' then
      consume()
      content = content .. ((current_char == '{' or current_char == '}') and consume() or '\\')
    elseif current_char == '{' then
      if content ~= '' then commit(content, content_line) end
      content_line, content = current_line, ''
      tokenize_interpolation(tokenize_token)
    else
      content = content .. consume()
    end
  end

  if content ~= '' then
    commit(content, content_line)
  end

  commit(consume(close_quote_len))
end

-- -----------------------------------------------------------------------------
-- Misc Tokenizers
-- -----------------------------------------------------------------------------

local function tokenize_word()
  local token = consume()

  while C.WORD_BODY[current_char] do
    token = token .. consume()
  end

  commit(token)
end

local function tokenize_comment()
  consume(2) -- '--'

  local is_block_comment, equals = false, ''

  if current_char == '[' then
    consume()

    while current_char == '=' do
      equals = equals .. consume()
    end

    if current_char == '[' then
      consume()
      is_block_comment = true
    end
  end

  if not is_block_comment then
    while current_char ~= '' and current_char ~= '\n' do
      consume()
    end
  else
    local close_quote = ']' .. equals .. ']'
    local close_quote_len = #close_quote
    local comment_line = current_line

    -- Check `current_char ~= ']'` first as slight optimization
    while current_char ~= ']' or peek(close_quote_len) ~= close_quote do
      if current_char == '' then
        throw('unterminated comment', comment_line)
      elseif current_char == '\n' then
        newline()
      else
        consume()
      end
    end

    consume(close_quote_len)
  end
end

function tokenize_token()
  if current_char == '\n' then
    newline()
  elseif current_char == ' ' or current_char == '\t' then
    consume()
  elseif C.WORD_HEAD[current_char] then
    tokenize_word()
  elseif current_char == "'" then
    tokenize_single_quote_string()
  elseif current_char == '"' then
    tokenize_double_quote_string(tokenize_token)
  else
    local peek_two = peek(2)
    if peek_two == '--' then
      tokenize_comment()
    elseif peek_two == '0x' or peek_two == '0X' then
      tokenize_hex()
    elseif peek_two == '0b' or peek_two == '0B' then
      tokenize_binary()
    elseif C.DIGIT[current_char] or (current_char == '.' and C.DIGIT[look_ahead(1)]) then
      tokenize_decimal()
    elseif peek_two == '[[' or peek_two == '[=' then
      tokenize_block_string(tokenize_token)
    elseif C.SYMBOLS[peek(3)] then
      commit(consume(3))
    elseif C.SYMBOLS[peek_two] then
      commit(consume(2))
    else
      commit(consume())
    end
  end
end

-- -----------------------------------------------------------------------------
-- Main
-- -----------------------------------------------------------------------------

return function(new_text, new_source_name)
  text = new_text
  current_char = text:sub(1, 1)
  current_char_index = 1
  current_line = 1
  tokens = {}
  num_tokens = 0
  token_lines = {}
  source_name = new_source_name or utils.get_source_alias(text)

  if peek(2) == '#!' then
    local token = consume(2)

    while current_char ~= '' and current_char ~= '\n' do
      token = token .. consume()
    end

    commit(token)
  end

  while current_char ~= '' do
    tokenize_token()
  end

  return {
    tokens = tokens,
    num_tokens = num_tokens,
    token_lines = token_lines,
  }
end
