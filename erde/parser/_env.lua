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

  -- Private State
  _buffer = {},
  _bufIndex = 1,
  _bufValue = 0,

  -- Public State
  state = 1,
  line = 1,
  column = 1,
}

for key, value in pairs(_G) do
  if env[key] == nil then
    env[key] = value
  end
end

local states = {
  'STATE_FREE',
  'STATE_NUMBER',
  'STATE_STRING',
  'STATE_EXPR',
}

for key, value in pairs(states) do
  env[value] = value
end

local tags = {
  'TAG_NUMBER',
  'TAG_LONG_STRING',
}

for key, value in pairs(tags) do
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
-- Token
-- -----------------------------------------------------------------------------

local Token_mt = {
  __index = {
    consume = function(self, n)
      for i = 1, n or 1 do
        self.buffer[#self.buffer + 1] = bufValue
        next()
      end
    end,
    commit = function(self)
      self[#self + 1] = table.concat(self.buffer)
      self.buffer = {}
    end,
  },
}

function env.Token(tag)
  return setmetatable({
    line = line,
    column = column,
    buffer = {},
    tag = tag,
  }, Token_mt)
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
    if type(target) == 'table' then
      target[#target + 1] = bufValue
    end
    next()
  end
end

-- -----------------------------------------------------------------------------
-- Error Handling
-- -----------------------------------------------------------------------------

env.assert = {
  state = function(expectedState, receivedState)
    receivedState = receivedState or state
    if expectedState ~= receivedState then
      throw.badState(receivedState, expectedState)
    end
  end,
}

env.throw = {
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
