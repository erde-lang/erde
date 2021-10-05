-- -----------------------------------------------------------------------------
-- Init
-- -----------------------------------------------------------------------------

local _env = {
  -- Constants
  Newline = string.byte('\n'),
  Dot = string.byte('.'),
  Alpha = {},
  Digit = {},
  Hex = {},

  -- State
  state = STATE_NUMBER,
  buffer = {},
  bufIndex = 1,
  bufValue = 0,
  token = {},
  line = 1,
  column = 1,
}

for key, value in pairs(_G) do
  if _env[key] == nil then
    _env[key] = value
  end
end

local _states = {
  'STATE_FREE',
  'STATE_NUMBER',
  'STATE_NUMBER_DECIMAL',
  'STATE_STRING',
}

for key, value in pairs(_states) do
  _env[value] = key
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

_ENV = load()

for byte = string.byte('0'), string.byte('9') do
  Digit[byte] = true
  Hex[byte] = true
end
for byte = string.byte('A'), string.byte('F') do
  _env[string.char(byte)] = byte
  Hex[byte] = true
  Alpha[byte] = true
end
for byte = string.byte('G'), string.byte('Z') do
  _env[string.char(byte)] = byte
  Alpha[byte] = true
end
for byte = string.byte('a'), string.byte('f') do
  _env[string.char(byte)] = byte
  Hex[byte] = true
  Alpha[byte] = true
end
for byte = string.byte('g'), string.byte('z') do
  _env[string.char(byte)] = byte
  Alpha[byte] = true
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return { load = load }
