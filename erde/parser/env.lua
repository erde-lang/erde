local Environment = require('erde.Environment')
local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Environment
-- -----------------------------------------------------------------------------

local env = Environment()
env:merge(constants)
env:merge(_G)
local _ENV = env:load()

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

buffer = {}
bufIndex = 1
bufValue = 0
line = 1
column = 1

-- -----------------------------------------------------------------------------
-- Lookup Tables
-- -----------------------------------------------------------------------------

UpperCase = {}
Alpha = {}
Digit = {}
Hex = {}
Whitespace = {
  ['\n'] = true,
  ['\t'] = true,
  [' '] = true,
}

for byte = string.byte('0'), string.byte('9') do
  local char = string.char(byte)
  Digit[char] = true
  Hex[char] = true
end
for byte = string.byte('A'), string.byte('F') do
  local char = string.char(byte)
  Alpha[char] = true
  Hex[char] = true
  UpperCase[char] = true
end
for byte = string.byte('G'), string.byte('Z') do
  local char = string.char(byte)
  Alpha[char] = true
  UpperCase[char] = true
end
for byte = string.byte('a'), string.byte('f') do
  local char = string.char(byte)
  Alpha[char] = true
  Hex[char] = true
end
for byte = string.byte('g'), string.byte('z') do
  local char = string.char(byte)
  Alpha[char] = true
end

-- -----------------------------------------------------------------------------
-- Error Handling
-- -----------------------------------------------------------------------------

throw = {}

local function getErrorToken()
  if Alpha[bufValue] or Digit[bufValue] then
    local word = {}

    while Alpha[bufValue] or Digit[bufValue] do
      consume(1, word)
    end

    return table.concat(word)
  elseif bufValue == EOF then
    return 'EOF'
  else
    return bufValue
  end
end

function throw.error(msg)
  error(('Error (Line %d, Col %d): %s'):format(line, column, msg))
end

function throw.expected(expectation, noLiteral)
  local msg = 'Expected ' .. (noLiteral and '%s' or '`%s`') .. ', got `%s`'
  throw.error(msg:format(expectation, getErrorToken()))
end

function throw.unexpected()
  throw.error(('Unexpected token %s'):format(getErrorToken()))
end

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

function loadBuffer(input)
  buffer = {}
  for i = 1, #input do
    buffer[i] = input:sub(i, i)
  end
  buffer[#buffer + 1] = EOF

  bufIndex = 1
  bufValue = buffer[bufIndex]
  line = 1
  column = 1
end

function consume(n, capture)
  n = n or 1

  if type(capture) == 'table' then
    for i = 0, n - 1 do
      capture[#capture + 1] = buffer[bufIndex + i]
    end
  end

  for i = 1, n do
    if bufValue == EOF then
      throw.unexpected()
    end

    bufIndex = bufIndex + 1
    bufValue = buffer[bufIndex]

    if bufValue == Newline then
      line = line + 1
      column = 1
    else
      column = column + 1
    end
  end
end

function peek(n)
  local word = { bufValue }

  for i = 1, n - 1 do
    local char = buffer[bufIndex + i]
    if not char or char == EOF then
      break
    end
    word[#word + 1] = char
  end

  return table.concat(word)
end

function stream(lookupTable, capture, demand)
  if demand and not lookupTable[bufValue] then
    error('unexpected value')
  end

  while lookupTable[bufValue] do
    consume(1, capture)
  end
end

function branch(n, isBranch, noPad, capture)
  if not noPad then
    parser.space()
  end

  if isBranch then
    consume(n, capture)
  end

  if not noPad then
    parser.space()
  end

  return isBranch
end

function branchChar(char, noPad, capture)
  return branch(
    1,
    -- Slight optimization for most common case
    #char > 1 and char:find(bufValue) or bufValue == char,
    noPad,
    capture
  )
end

function branchStr(str, noPad, capture)
  return branch(#str, peek(#str) == str, noPad, capture)
end

function branchWord(word, capture)
  local trailingChar = buffer[bufIndex + #word]
  return not (Alpha[trailingChar] or Digit[trailingChar])
    and branchStr(word, false, capture)
end

-- -----------------------------------------------------------------------------
-- Parser
-- -----------------------------------------------------------------------------

parser = setmetatable({}, {
  __newindex = function(parser, key, value)
    if UpperCase[key:sub(1, 1)] then
      rawset(parser, key, function(...)
        parser.space()

        local node = value(...)
        if not node.rule then
          node.rule = key
        end

        parser.space()
        return node
      end)
    else
      rawset(parser, key, value)
    end
  end,
})

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return env
