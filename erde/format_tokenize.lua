local C = require('erde.constants')

-- TODO: can do some optimizations by simply committing strings directly and
-- 'skipping', so we don't have to unnecessarily peek in consume
--
-- OLD:
-- if peek(2) == '--' then
--  commit(consume(2))
-- end
--
-- NEW:
-- if peek(2) == '--' then
--  commit('--')
--  skip(2)
-- end

-- Foward declare
local Token

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local text, char, charIndex
local line, column
local tokens, numTokens, tokenInfo
local newlines

local token
local numLookup, numExp1, numExp2

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function commit(token)
  numTokens = numTokens + 1
  tokens[numTokens] = token
  tokenInfo[numTokens] = { line = line, column = column }
  column = column + #token
end

local function peek(n)
  return text:sub(charIndex, charIndex + n - 1)
end

local function consume(n)
  n = n or 1
  local consumed = n == 1 and char or peek(n)
  charIndex = charIndex + n
  char = text:sub(charIndex, charIndex)
  return consumed
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

local function Newline()
  column = 1
  line = line + 1
  return consume()
end

local function Space()
  while char == ' ' or char == '\t' do
    consume()
    column = column + 1
  end
end

local function Number()
  while numLookup[char] do
    token = token .. consume()
  end

  if char == '.' then
    token = token .. consume()

    if not numLookup[char] then
      error('Missing number after decimal point')
    end

    while numLookup[char] do
      token = token .. consume()
    end
  end

  if char == numExp1 or char == numExp2 then
    token = token .. consume()

    if char == '+' or char == '-' then
      token = token .. consume()
    end

    if not C.DIGIT[char] then
      error('Missing number after exponent')
    end

    while C.DIGIT[char] do
      token = token .. consume()
    end
  end

  if C.ALPHA[char] then
    error('Words cannot start with a digit')
  end

  commit(token)
end

local function InnerString()
  if char == '' then
    error('Unexpected EOF (unterminated string)')
  elseif char == '\\' then
    token = token .. consume(2)
  elseif char == '{' then
    if #token > 0 then
      commit(token)
    end

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
        error('Unexpected EOF (unterminated interpolation)')
      else
        Token()
      end

      Space()
    end

    commit(consume()) -- '}'
    token = ''
  else
    token = token .. consume()
  end
end

function Token()
  local peekTwo = peek(2)
  token = ''

  if C.WORD_HEAD[char] then
    token = consume()

    while C.WORD_BODY[char] do
      token = token .. consume()
    end

    commit(token)
  elseif C.DIGIT[char] then
    if peekTwo == '0x' or peekTwo == '0X' then
      numLookup = C.HEX
      numExp1, numExp2 = 'p', 'P'

      token = consume(2) -- 0[xX]
      if not C.HEX[char] and char ~= '.' then
        error('Missing hex after ' .. token)
      end
    else
      numLookup = C.DIGIT
      numExp1, numExp2 = 'e', 'E'
    end

    Number()
  elseif peekTwo:match('%.[0-9]') then
    numLookup = C.DIGIT
    numExp1, numExp2 = 'e', 'E'
    Number()
  elseif C.SYMBOLS[peek(3)] then
    commit(consume(3))
  elseif C.SYMBOLS[peekTwo] then
    commit(consume(2))
  elseif char == '\n' then
    local numNewLines = 0

    while char == '\n' do
      numNewLines = numNewLines + 1
      Newline()
      Space()
    end

    newlines[numTokens] = numNewLines
  elseif char == '"' or char == "'" then
    local quote = consume()
    commit(quote)

    while char ~= quote do
      if char == '\n' then
        error('Unexpected newline (unterminated string)')
      else
        InnerString()
      end
    end

    if #token > 0 then
      commit(token)
    end

    commit(consume()) -- quote
  elseif peekTwo:match('%[[[=]') then
    consume() -- '['

    local strEq, strCloseLen = '', 2
    while char == '=' do
      strEq = strEq .. consume()
      strCloseLen = strCloseLen + 1
    end

    if char ~= '[' then
      error('Invalid start of long string (expected [ got ' .. char .. ')')
    else
      consume()
    end

    commit('[' .. strEq .. '[')
    strClose = ']' .. strEq .. ']'

    while peek(strCloseLen) ~= strClose do
      if char == '\n' then
        token = token .. Newline()
      else
        InnerString()
      end
    end

    if #token > 0 then
      commit(token)
    end

    commit(consume(strCloseLen))
  elseif peekTwo == '--' then
    commit(consume(2))
    Space()

    while char ~= '' and char ~= '\n' do
      token = token .. consume()
    end

    commit(token)
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
  tokens, numTokens, tokenInfo = {}, 0, {}
  newlines = {}

  if peek(2) == '#!' then
    token = consume(2)

    while char ~= '\n' do
      token = token .. consume()
    end

    commit(token)
    Newline()
  end

  local ok, errorMsg = pcall(function()
    while char ~= '' do
      Space()
      Token()
    end
  end)

  if not ok then
    error(('Error (Line %d, Column %d): %s'):format(line, column, errorMsg))
  end

  return tokens, tokenInfo, newlines
end
