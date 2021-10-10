-- -----------------------------------------------------------------------------
-- Init
-- -----------------------------------------------------------------------------

local env = {
  -- Constants
  EOF = -1,

  -- Lookup Tables
  Alpha = {},
  Digit = {},
  Hex = {},

  -- Public State
  state = 1,
  buffer = {},
  bufIndex = 1,
  bufValue = 0,
  line = 1,
  column = 1,

  -- Parsers
  -- `parser` is the actual parser. `unit` is used to parse individual
  -- components and is particularly useful for unit tests.
  parser = {},
  unit = {},
}

for key, value in pairs(_G) do
  if env[key] == nil then
    env[key] = value
  end
end

local STATES = {
  'STATE_FREE',

  -- Number
  'STATE_NUMBER',
  'STATE_HEX',
  'STATE_FLOAT',
  'STATE_EXPONENT',
  'STATE_EXPONENT_SIGN',

  -- String
  'STATE_STRING',
  'STATE_SHORT_STRING',
  'STATE_LONG_STRING',

  'STATE_EXPR',
}

for key, value in pairs(STATES) do
  env[value] = value
end

local TAGS = {
  'TAG_NUMBER',
  'TAG_LONG_STRING',
}

for key, value in pairs(TAGS) do
  env[value] = value
end

-- -----------------------------------------------------------------------------
-- Loader
-- -----------------------------------------------------------------------------

local function load()
  if _VERSION:find('5.1') then
    setfenv(2, env)
  else
    return env
  end
end

-- -----------------------------------------------------------------------------
-- Setup
-- -----------------------------------------------------------------------------

local _ENV = load()

for byte = string.byte('0'), string.byte('9') do
  local char = string.char(byte)
  Digit[char] = true
  Hex[char] = true
end
for byte = string.byte('A'), string.byte('F') do
  local char = string.char(byte)
  Hex[char] = true
  Alpha[char] = true
end
for byte = string.byte('G'), string.byte('Z') do
  local char = string.char(byte)
  Alpha[char] = true
end
for byte = string.byte('a'), string.byte('f') do
  local char = string.char(byte)
  Hex[char] = true
  Alpha[char] = true
end
for byte = string.byte('g'), string.byte('z') do
  local char = string.char(byte)
  Alpha[char] = true
end

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

function env.loadBuffer(input)
  state = STATE_FREE

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

function env.next()
  bufIndex = bufIndex + 1
  bufValue = buffer[bufIndex]

  if bufValue == Newline then
    line = line + 1
    column = 1
  else
    column = column + 1
  end
end

function env.consume(n, target)
  for i = 1, n or 1 do
    target[#target + 1] = bufValue
    next()
  end
end

-- -----------------------------------------------------------------------------
-- Error Handling
-- -----------------------------------------------------------------------------

env.assert = {
  state = function(expectedState)
    if state ~= expectedState then
      throw.badState(expectedState)
    end
  end,
}

env.throw = {
  badState = function(expectedState)
    if expectedState == nil then
      error(('Invalid state: %s'):format(state))
    else
      error(('Invalid state. Expected %s, got %s'):format(expectedState, state))
    end
  end,
}

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return { load = load }
