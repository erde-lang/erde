local C = require('erde.constants')
local utils = require('erde.utils')

-- Foward declare
local token

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local text, char, char_index, current_line
local tokens, token_lines, num_tokens

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function commit(token, line)
  num_tokens = num_tokens + 1
  tokens[num_tokens] = token
  token_lines[num_tokens] = line or current_line
end

local function peek(n)
  return text:sub(char_index, char_index + n - 1)
end

local function look_ahead(n)
  return text:sub(char_index + n, char_index + n)
end

local function consume(n)
  n = n or 1
  local consumed = n == 1 and char or peek(n)
  char_index = char_index + n
  char = text:sub(char_index, char_index)
  return consumed
end

local function throw(message, line)
  utils.erde_error({ message = message, line = line or current_line })
end

-- -----------------------------------------------------------------------------
-- Partials
--
-- These functions return tokens instead of committing tokens.
-- -----------------------------------------------------------------------------

local function Newline()
  current_line = current_line + 1
  return consume()
end

local function EscapeSequence()
  if C.STANDARD_ESCAPE_CHARS[char] then
    return consume()
  elseif C.DIGIT[char] then
    return consume()
  elseif char == 'z' then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      throw('escape sequence \\z only compatible w/ lua targets 5.2+, jit')
    end
    return consume()
  elseif char == 'x' then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      throw('escape sequence \\xXX only compatible w/ lua targets 5.2+, jit')
    end

    local EscapeSequence = consume()

    for i = 1, 2 do
      if not C.HEX[char] then
        throw('escape sequence \\xXX must use exactly 2 hex characters')
      end
      EscapeSequence = EscapeSequence .. consume()
    end

    return EscapeSequence
  elseif char == 'u' then
    local EscapeSequence = consume()

    if char ~= '{' then
      throw('missing { in escape sequence \\u{XXX}')
    elseif C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' or C.LUA_TARGET == '5.2' or C.LUA_TARGET == '5.2+' then
      throw('escape sequence \\u{XXX} only compatible w/ lua targets 5.3+, jit')
    end

    EscapeSequence = EscapeSequence .. consume()
    if not C.HEX[char] then
      throw('missing hex in escape sequence \\u{XXX}')
    end

    while C.HEX[char] do
      EscapeSequence = EscapeSequence .. consume()
    end

    if char ~= '}' then
      throw('missing } in escape sequence \\u{XXX}')
    end

    return EscapeSequence .. consume()
  else
    throw('invalid escape sequence \\' .. char)
  end
end

-- -----------------------------------------------------------------------------
-- Macros
--
-- These functions commit (possibly) multiple tokens when called.
-- -----------------------------------------------------------------------------

local function Word()
  local token = consume()

  while C.WORD_BODY[char] do
    token = token .. consume()
  end

  commit(token)
end

local function Hex()
  local token = consume(2) -- 0[xX]

  if not C.HEX[char] and not (char == '.' and C.HEX[look_ahead(1)]) then
    throw('malformed hex')
  end

  while C.HEX[char] do
    token = token .. consume()
  end

  if char == '.' and C.HEX[look_ahead(1)] then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      throw('hex fractional parts only compatible w/ lua targets 5.2+, jit')
    end

    token = token .. consume(2)
    while C.HEX[char] do
      token = token .. consume()
    end
  end

  if char == 'p' or char == 'P' then
    token = token .. consume()

    if char == '+' or char == '-' then
      if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
        throw('hex exponent sign only compatible w/ lua targets 5.2+, jit')
      end
      token = token .. consume()
    end

    if not C.DIGIT[char] then
      throw('missing exponent value')
    end

    while C.DIGIT[char] do
      token = token .. consume()
    end
  end

  commit(token)
end

local function Binary()
  if C.LUA_TARGET ~= 'jit' then
    throw('binary literals only compatible w/ lua target jit')
  end

  local token = consume(2) -- 0[bB]

  if char ~= '0' and char ~= '1' then
    throw('malformed hex')
  end

  repeat
    token = token .. consume()
  until char ~= '0' and char ~= '1'

  commit(token)
end

local function Decimal()
  local token = ''

  while C.DIGIT[char] do
    token = token .. consume()
  end

  if char == '.' and C.DIGIT[look_ahead(1)] then
    token = token .. consume(2)
    while C.DIGIT[char] do
      token = token .. consume()
    end
  end

  if char == 'e' or char == 'E' then
    token = token .. consume()

    if char == '+' or char == '-' then
      token = token .. consume()
    end

    if not C.DIGIT[char] then
      throw('missing exponent value')
    end

    while C.DIGIT[char] do
      token = token .. consume()
    end
  end

  commit(token)
end

local function Interpolation()
  commit(consume()) -- '{'

  -- Keep track of brace depth to differentiate end of interpolation from
  -- nested braces
  local brace_depth, interpolation_line = 0, current_line

  while char ~= '}' or brace_depth > 0 do
    if char == '{' then
      brace_depth = brace_depth + 1
      commit(consume())
    elseif char == '}' then
      brace_depth = brace_depth - 1
      commit(consume())
    elseif char == '\n' then
      Newline()
    elseif char == ' ' or char == '\t' then
      consume()
    elseif char == '' then
      throw('unterminated interpolation', interpolation_line)
    else
      Token()
    end
  end

  commit(consume()) -- '}'
end

local function SingleQuoteString()
  commit(consume()) -- quote

  local content = ''

  while char ~= "'" do
    if char == '' or char == '\n' then
      throw('unterminated string')
    elseif char == '\\' then
      content = content .. consume() .. EscapeSequence()
    else
      content = content .. consume()
    end
  end

  if content ~= '' then
    commit(content)
  end

  commit(consume()) -- quote
end

local function DoubleQuoteString()
  commit(consume()) -- quote

  -- Keep track of content_line in case interpolation has newline
  local content, content_line = '', current_line

  while char ~= '"' do
    if char == '' or char == '\n' then
      throw('unterminated string')
    elseif char == '\\' then
      consume()
      if char == '{' or char == '}' then
        content = content .. consume()
      else
        content = content .. '\\' .. EscapeSequence()
      end
    elseif char == '{' then
      if content ~= '' then
        commit(content, content_line)
        content, content_line = '', current_line
      end
      Interpolation()
    else
      content = content .. consume()
    end
  end

  if content ~= '' then
    commit(content, content_line)
  end

  commit(consume()) -- quote
end

local function BlockString()
  consume() -- '['

  local open_quote, close_quote, quote_len = '[', ']', 1

  while char == '=' do
    consume()
    open_quote = open_quote .. '='
    close_quote = close_quote .. '='
    quote_len = quote_len + 1
  end

  if char ~= '[' then
    throw('unterminated block string opening', content_line)
  else
    consume()
    open_quote = open_quote .. '['
    close_quote = close_quote .. ']'
    quote_len = quote_len + 1
  end

  commit(open_quote)

  local content, content_line = '', current_line

  while char ~= ']' or peek(quote_len) ~= close_quote do
    if char == '' then
      throw('unterminated block string', content_line)
    elseif char == '\n' then
      content = content .. Newline()
    elseif char == '\\' then
      consume()
      if char == '{' or char == '}' then
        content = content .. consume()
      else
        content = content .. '\\' .. consume()
      end
    elseif char == '{' then
      if content ~= '' then
        commit(content, content_line)
        content, content_line = '', current_line
      end
      Interpolation()
    else
      content = content .. consume()
    end
  end

  if content ~= '' then
    commit(content, content_line)
  end

  commit(consume(quote_len))
end

local function Comment()
  consume(2) -- '--'

  local is_block_comment, close_quote, close_quote_len = false, ']', 1

  if char == '[' then
    consume()

    while char == '=' do
      close_quote = close_quote .. consume()
      close_quote_len = close_quote_len + 1
    end

    if char == '[' then
      consume()
      is_block_comment = true
      close_quote = close_quote .. ']'
      close_quote_len = close_quote_len + 1
    end
  end

  if not is_block_comment then
    while char ~= '' and char ~= '\n' do
      consume()
    end
  else
    local comment_line = current_line

    while char ~= ']' or peek(close_quote_len) ~= close_quote do
      if char == '' then
        throw('unterminated comment', comment_line)
      elseif char == '\n' then
        Newline()
      else
        consume()
      end
    end

    consume(close_quote_len)
  end
end

function Token()
  if C.WORD_HEAD[char] then
    Word()
  elseif char == "'" then
    SingleQuoteString()
  elseif char == '"' then
    DoubleQuoteString()
  else
    local peek_two = peek(2)
    if peek_two == '--' then
      Comment()
    elseif peek_two == '0x' or peek_two == '0X' then
      Hex()
    elseif peek_two == '0b' or peek_two == '0B' then
      Binary()
    elseif C.DIGIT[char] or (char == '.' and C.DIGIT[look_ahead(1)]) then
      Decimal()
    elseif peek_two == '[[' or peek_two == '[=' then
      BlockString()
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
-- tokenize
-- -----------------------------------------------------------------------------

return function(new_text)
  text, char, char_index, current_line = new_text, new_text:sub(1, 1), 1, 1
  tokens, token_lines, num_tokens = {}, {}, 0

  if peek(2) == '#!' then
    local token = consume(2)

    while char ~= '' and char ~= '\n' do
      token = token .. consume()
    end

    commit(token)
  end

  while char ~= '' do
    if char == '\n' then
      Newline()
    elseif char == ' ' or char == '\t' then
      consume()
    else
      Token()
    end
  end

  return tokens, token_lines, num_tokens
end
