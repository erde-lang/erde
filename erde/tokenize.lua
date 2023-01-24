local C = require('erde.constants')
local utils = require('erde.utils')

-- Foward declare
local Token

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local text, char, charIndex, line
local tokens, numTokens, tokenLines

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function commit(token)
  numTokens = numTokens + 1
  tokens[numTokens] = token
  tokenLines[numTokens] = line
end

local function peek(n)
  return text:sub(charIndex, charIndex + n - 1)
end

local function lookAhead(n)
  return text:sub(charIndex + n, charIndex + n)
end

local function consume(n)
  n = n or 1
  local consumed = n == 1 and char or peek(n)
  charIndex = charIndex + n
  char = text:sub(charIndex, charIndex)
  return consumed
end

local function throw(message, errLine)
  utils.erdeError({
    message = message,
    line = errLine or line,
  })
end

-- -----------------------------------------------------------------------------
-- Partials
-- -----------------------------------------------------------------------------

local function Newline()
  line = line + 1
  return consume()
end

local function EscapeChar(preventInterpolation)
  consume() -- backslash

  if not preventInterpolation and (char == '{' or char == '}') then
    return consume()
  elseif C.STANDARD_ESCAPE_CHARS[char] then
    return '\\' .. consume()
  elseif C.DIGIT[char] then
    return '\\' .. consume()
  elseif char == 'z' then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      throw('escape sequence \\z only compatible w/ lua targets 5.2+, jit')
    end
    return '\\' .. consume()
  elseif char == 'x' then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      throw('escape sequence \\xXX only compatible w/ lua targets 5.2+, jit')
    end

    local escapeChar = '\\' .. consume()

    for i = 1, 2 do
      if not C.HEX[char] then
        throw('escape sequence \\xXX must use exactly 2 hex characters')
      end
      escapeChar = escapeChar .. consume()
    end

    return escapeChar
  elseif char == 'u' then
    local escapeChar = '\\' .. consume()

    if char ~= '{' then
      throw('missing { in escape sequence \\u{XXX}')
    elseif C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' or C.LUA_TARGET == '5.2' or C.LUA_TARGET == '5.2+' then
      throw('escape sequence \\u{XXX} only compatible w/ lua targets 5.3+, jit')
    end

    escapeChar = escapeChar .. consume()
    if not C.HEX[char] then
      throw('missing hex in escape sequence \\u{XXX}')
    end

    while C.HEX[char] do
      escapeChar = escapeChar .. consume()
    end

    if char ~= '}' then
      throw('missing } in escape sequence \\u{XXX}')
    end

    return escapeChar .. consume()
  else
    throw('invalid escape sequence \\' .. char)
  end
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

local function Space()
  while char == ' ' or char == '\t' do
    consume()
  end
end

local function Word()
  local token = consume()

  while C.WORD_BODY[char] do
    token = token .. consume()
  end

  commit(token)
end

local function Hex()
  local token = consume(2) -- 0[xX]

  if not C.HEX[char] and not (char == '.' and C.HEX[lookAhead(1)]) then
    throw('malformed hex')
  end

  while C.HEX[char] do
    token = token .. consume()
  end

  if char == '.' and C.HEX[lookAhead(1)] then
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
  local token = consume(2) -- 0[bB]

  if C.LUA_TARGET ~= 'jit' then
    throw('binary literals only compatible w/ lua target jit')
  end

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

  if char == '.' and C.DIGIT[lookAhead(1)] then
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
  Space()

  -- Keep track of brace depth to differentiate end of interpolation from
  -- nested braces
  local braceDepth = 0

  while char ~= '}' or braceDepth > 0 do
    if char == '{' then
      braceDepth = braceDepth + 1
      commit(consume())
    elseif char == '}' then
      braceDepth = braceDepth - 1
      commit(consume())
    elseif char == '' then
      throw('unexpected eof (unterminated interpolation)')
    else
      Token()
    end

    Space()
  end

  commit(consume()) -- '}'
end

local function SingleQuoteString()
  local quote, content = consume(), ''
  commit(quote)

  while char ~= quote do
    if char == '' then
      throw('unexpected eof (unterminated string)')
    elseif char == '\n' then
      throw('unterminated string')
    elseif char == '\\' then
      content = content .. EscapeChar(true)
    else
      content = content .. consume()
    end
  end

  if content ~= '' then commit(content) end
  commit(consume()) -- quote
end

local function DoubleQuoteString()
  local quote, content = consume(), ''
  commit(quote)

  while char ~= quote do
    if char == '' then
      throw('unexpected eof (unterminated string)')
    elseif char == '\n' then
      throw('unterminated string')
    elseif char == '\\' then
      content = content .. EscapeChar()
    elseif char == '{' then
      if content ~= '' then
        commit(content)
        content = ''
      end
      Interpolation()
    else
      content = content .. consume()
    end
  end

  if content ~= '' then commit(content) end
  commit(consume()) -- quote
end

local function LongString()
  local firstLine = line
  consume() -- '['

  local strEq, strCloseLen = '', 2
  while char == '=' do
    strEq = strEq .. consume()
    strCloseLen = strCloseLen + 1
  end

  consume() -- '['
  commit('[' .. strEq .. '[')
  strClose = ']' .. strEq .. ']'
  content = ''

  while peek(strCloseLen) ~= strClose do
    if char == '' then
      throw('unexpected eof (unterminated string)', firstLine)
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
        commit(content)
        content = ''
      end
      Interpolation()
    else
      content = content .. consume()
    end
  end

  if content ~= '' then commit(content) end
  commit(consume(strCloseLen)) -- `strClose`
end

local function Comment()
  local firstLine = line
  consume(2) -- '--'

  if not text:sub(charIndex):match('^%[=*%[') then
    while char ~= '' and char ~= '\n' do
      consume()
    end
  else
    consume() -- '['

    local strEq, strCloseLen = '', 2
    while char == '=' do
      strEq = strEq .. consume()
      strCloseLen = strCloseLen + 1
    end

    consume()
    local strClose = ']' .. strEq .. ']'

    while peek(strCloseLen) ~= strClose do
      if char == '' then
        throw('unexpected eof (unterminated comment)', firstLine)
      elseif char == '\n' then
        Newline()
      else
        consume()
      end
    end

    consume(strCloseLen)
  end
end

-- -----------------------------------------------------------------------------
-- Token
-- -----------------------------------------------------------------------------

function Token()
  local peekTwo = peek(2)

  if char == '\n' then
    repeat
      Newline()
      Space()
    until char ~= '\n'
  elseif C.WORD_HEAD[char] then
    Word()
  elseif peekTwo:match('0[xX]') then
    Hex()
  elseif peekTwo:match('0[bB]') then
    Binary()
  elseif C.DIGIT[char] or (char == '.' and C.DIGIT[lookAhead(1)]) then
    Decimal()
  elseif char == "'" then
    SingleQuoteString()
  elseif char == '"' then
    DoubleQuoteString()
  elseif text:sub(charIndex):match('^%[=*%[') then
    LongString()
  elseif peekTwo == '--' then
    Comment()
  elseif C.SYMBOLS[peek(3)] then
    commit(consume(3))
  elseif C.SYMBOLS[peekTwo] then
    commit(consume(2))
  else
    commit(consume())
  end
end

-- -----------------------------------------------------------------------------
-- Tokenize
-- -----------------------------------------------------------------------------

return function(input)
  text, char, charIndex, line = input, input:sub(1, 1), 1, 1
  tokens, numTokens, tokenLines = {}, 0, {}

  if peek(2) == '#!' then
    local shebang = consume(2)

    while char ~= '\n' do
      shebang = shebang .. consume()
    end

    commit(shebang)
    Newline()
  end

  Space()
  while char ~= '' do
    Token()
    Space()
  end

  return tokens, tokenLines
end
