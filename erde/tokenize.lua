local C = require('erde.constants')

-- Foward declare
local Token

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local text, char, charIndex
local line, column
local tokens, numTokens, tokenLines

local token
local numLookup, numExp1, numExp2

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function commit(token)
  numTokens = numTokens + 1
  tokens[numTokens] = token
  tokenLines[numTokens] = line
  column = column + #token
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

-- -----------------------------------------------------------------------------
-- Partials
-- -----------------------------------------------------------------------------

local function Newline()
  column = 1
  line = line + 1
  return consume()
end

local function EscapeChar()
  consume() -- backslash

  if char == '{' or char == '}' then
    return consume()
  elseif C.STANDARD_ESCAPE_CHARS[char] then
    return '\\' .. consume()
  elseif C.DIGIT[char] then
    return '\\' .. consume()
  elseif char == 'z' then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      error('escape sequence \\z not compatible w/ lua target ' .. C.LUA_TARGET)
    end
    return '\\' .. consume()
  elseif char == 'x' then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      error('escape sequence \\xXX not compatible w/ lua target ' .. C.LUA_TARGET)
    end

    local escapeChar = '\\' .. consume()

    for i = 1, 2 do
      if not C.HEX[char] then
        error('\\x must be followed by exactly 2 hex characters')
      end
      escapeChar = escapeChar .. consume()
    end

    return escapeChar
  elseif char == 'u' then
    local escapeChar = consume()

    if char ~= '{' then
      error('missing { in escape sequence \\u{XXX}')
    elseif C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' or C.LUA_TARGET == '5.2' or C.LUA_TARGET == '5.2+' then
      error('escape sequence \\u{XXX} not compatible w/ lua target ' .. C.LUA_TARGET)
    end

    escapeChar = escapeChar .. consume()
    if not C.HEX[char] then
      error('missing hex in escape sequence \\u{XXX}')
    end

    while C.HEX[char] do
      escapeChar = escapeChar .. consume()
    end

    if char ~= '}' then
      error('missing } in escape sequence \\u{XXX}')
    end

    return escapeChar .. consume()
  else
    error('invalid escape sequence \\' .. char)
  end
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

local function Space()
  while char == ' ' or char == '\t' do
    consume()
    column = column + 1
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
    error('malformed hex')
  end

  while C.HEX[char] do
    token = token .. consume()
  end

  if char == '.' and C.HEX[lookAhead(1)] then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      error('hex fractional parts not compatible w/ lua target ' .. C.LUA_TARGET)
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
        error('hex exponent sign not compatible w/ lua target ' .. C.LUA_TARGET)
      end
      token = token .. consume()
    end

    if not C.DIGIT[char] then
      error('missing exponent value')
    end

    while C.DIGIT[char] do
      token = token .. consume()
    end
  end

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
      error('missing exponent value')
    end

    while C.DIGIT[char] do
      token = token .. consume()
    end
  end

  commit(token)
end

local function SingleQuoteString()
  local quote, content = consume(), ''
  commit(quote)

  while char ~= quote do
    if char == '' then
      error('unterminated string')
    elseif char == '\n' then
      error('unexpected newline')
    elseif char == '\\' then
      content = content .. EscapeChar()
    else
      content = content .. consume()
    end
  end

  if content ~= '' then commit(content) end
  commit(consume()) -- quote
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
      error('unterminated interpolation')
    else
      Token()
    end

    Space()
  end

  commit(consume()) -- '}'
end

local function DoubleQuoteString()
  local quote, content = consume(), ''
  commit(quote)

  while char ~= quote do
    if char == '' then
      error('unterminated string')
    elseif char == '\n' then
      error('unexpected newline')
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
      error('unterminated string')
    elseif char == '\n' then
      content = content .. Newline()
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
  commit(consume(strCloseLen)) -- `strClose`
end

local function Comment()
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
        error('unterminated comment')
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
  text, char, charIndex = input, input:sub(1, 1), 1
  line, column = 1, 1
  tokens, numTokens, tokenLines = {}, 0, {}

  if peek(2) == '#!' then
    local shebang = consume(2)

    while char ~= '\n' do
      shebang = shebang .. consume()
    end

    commit(shebang)
    Newline()
  end

  local ok, errorMsg = pcall(function()
    Space()
    while char ~= '' do
      Token()
      Space()
    end
  end)

  if not ok then
    error(('Error (Line %d, Column %d): %s'):format(line, column, errorMsg))
  end

  return tokens, tokenLines
end
