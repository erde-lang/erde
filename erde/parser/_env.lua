-- -----------------------------------------------------------------------------
-- Init
-- -----------------------------------------------------------------------------

local _env = {
  -- Constants
  EOF = -1,

  -- Lookup Tables
  Alpha = {},
  Digit = {},
  Hex = {},

  -- State
  state = 1,
  buffer = {},
  bufIndex = 1,
  bufValue = 0,
  line = 1,
  column = 1,
}

for key, value in pairs(_G) do
  if _env[key] == nil then
    _env[key] = value
  end
end

local states = {
  'STATE_FREE',
  'STATE_NUMBER',
  'STATE_STRING',
}

for key, value in pairs(states) do
  _env[value] = value
end

-- -----------------------------------------------------------------------------
-- Loader
-- -----------------------------------------------------------------------------

local function load()
  if _VERSION:find('5.1') then
    setfenv(2, _env)
  else
    return _env
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

function _env.loadBuffer(input)
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

function _env.next()
  bufIndex = bufIndex + 1
  bufValue = buffer[bufIndex]

  if bufValue == Newline then
    line = line + 1
    column = 1
  else
    column = column + 1
  end
end

function _env.consume(n, target)
  for i = 1, n or 1 do
    if type(target) == 'table' then
      target[#target + 1] = bufValue
    end
    next()
  end
end

-- -----------------------------------------------------------------------------
-- Error Handling
-- -----------------------------------------------------------------------------

_env.assert = {
  state = function(expectedState, receivedState)
    receivedState = receivedState or state
    if expectedState ~= receivedState then
      throw.badState(receivedState, expectedState)
    end
  end,
}

_env.throw = {
  badState = function(receivedState, expectedState)
    if expectedState == nil then
      error(('Invalid state: %s'):format(receivedState or state))
    else
      error(
        ('Invalid state. Expected %s, got %s'):format(
          receivedState,
          expectedState
        )
      )
    end
  end,
}

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return { load = load }
