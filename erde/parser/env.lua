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
  Whitespace = {
    ['\n'] = true,
    [' '] = true,
  },

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

local function load()
  if _VERSION:find('5.1') then
    setfenv(2, env)
  else
    return env
  end
end

local _ENV = load()

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function enumify(enum)
  for _, value in pairs(enum) do
    if env[value] ~= nil then
      error('Duplicate enum: ' .. value)
    end
    env[value] = value
  end
end

-- -----------------------------------------------------------------------------
-- States
-- -----------------------------------------------------------------------------

enumify({
  'STATE_FREE',

  -- Number
  'STATE_DIGIT',
  'STATE_HEX',
  'STATE_FLOAT',
  'STATE_EXPONENT',
  'STATE_EXPONENT_SIGN',

  -- String
  'STATE_SHORT_STRING',
  'STATE_LONG_STRING',

  'STATE_EXPR',
})

-- -----------------------------------------------------------------------------
-- Tags
-- -----------------------------------------------------------------------------

enumify({
  'TAG_NUMBER',
  'TAG_LONG_STRING',

  -- Unops
  'TAG_NEG',
  'TAG_LEN',
  'TAG_NOT',
  'TAG_BNOT',

  -- Binops
  'TAG_NC',
  'TAG_OR',
  'TAG_AND',
  'TAG_EQ',
  'TAG_NEQ',
  'TAG_LTE',
  'TAG_GTE',
  'TAG_LT',
  'TAG_GT',
  'TAG_BOR',
  'TAG_BXOR',
  'TAG_BAND',
  'TAG_LSHIFT',
  'TAG_RSHIFT',
  'TAG_CONCAT',
  'TAG_ADD',
  'TAG_SUB',
  'TAG_MULT',
  'TAG_DIV',
  'TAG_INTDIV',
  'TAG_MOD',
  'TAG_EXP',
})

-- -----------------------------------------------------------------------------
-- Lookup Tables
-- -----------------------------------------------------------------------------

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

function env.consume(n, target)
  n = n or 1

  if type(target) == 'table' then
    for i = 0, n - 1 do
      target[#target + 1] = buffer[bufIndex + i]
    end
  end

  for i = 1, n do
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
