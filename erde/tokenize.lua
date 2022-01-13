-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local buffer, bufIndex, bufValue, tokens

-- -----------------------------------------------------------------------------
-- Lookup Tables
-- -----------------------------------------------------------------------------

local WORD_HEAD = { ['_'] = true }
local WORD_BODY = { ['_'] = true }
local DIGIT = {}

for byte = string.byte('a'), string.byte('z') do
  local char = string.char(byte)
  WORD_HEAD[char] = true
  WORD_BODY[char] = true
end

for byte = string.byte('A'), string.byte('Z') do
  local char = string.char(byte)
  WORD_HEAD[char] = true
  WORD_BODY[char] = true
end

for byte = string.byte('0'), string.byte('9') do
  local char = string.char(byte)
  WORD_BODY[char] = true
  DIGIT[char] = true
end

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function peek(n)
  return buffer:sub(bufIndex, bufIndex + n - 1)
end

local function consume(n)
  n = n or 1
  local consumed = n == 1 and bufValue or peek(n)
  bufIndex = bufIndex + n
  bufValue = buffer:sub(bufIndex, bufIndex)
  return consumed
end

local function space()
  while bufValue == ' ' or bufValue == '\t' do
    consume()
  end
end

local function LongString()
  consume() -- '['

  local strEq = ''
  while bufValue == '=' do
    strEq = strEq .. consume()
  end

  if consume() ~= '[' then
    -- TODO
    error()
  end

  local strOpen = '[' .. strEq .. '['
  local strClose = ']' .. strEq .. ']'
  local strContents = ''

  while bufValue ~= ']' or peek(#strClose) ~= strClose do
    -- TODO: what if end of buffer?
    strContents = strContents .. consume()
  end

  consume(#strClose)
  return strOpen .. strContents .. strClose
end

-- -----------------------------------------------------------------------------
-- Tokenize
-- -----------------------------------------------------------------------------

return function(input)
  buffer = input
  bufIndex = 1
  bufValue = buffer:sub(bufIndex, bufIndex)
  tokens = {}

  space()

  while bufValue ~= '' do
    local token = ''

    if bufValue == '\n' then
      token = '\n'
      while bufValue == '\n' do
        consume()
      end
    elseif WORD_HEAD[bufValue] then
      token = consume()
      while WORD_BODY[bufValue] do
        token = token .. consume()
      end
    elseif DIGIT[bufValue] then
      token = consume()
      while DIGIT[bufValue] do
        token = token .. consume()
      end
    elseif bufValue == '"' or bufValue == "'" then
      local strQuote = consume()
      token = strQuote
      local isEscaped = false

      repeat
        if bufValue == '' or bufValue == '\n' then
          break
        elseif bufValue == strQuote and not isEscaped then
          token = token .. consume()
          break
        else
          isEscaped = bufValue == '\\'
          token = token .. consume()
        end
      until false
    elseif peek(2):match('--') then
      token = consume(2)

      if peek(2):match('%[[[=]') then
        token = token .. LongString()
      else
        while bufValue ~= '' and bufValue ~= '\n' do
          token = token .. consume()
        end
      end
    elseif peek(2):match('%[[[=]') then
      token = LongString()
    else -- symbol
      token = consume()
    end

    tokens[#tokens + 1] = token

    space()
  end

  return tokens
end
