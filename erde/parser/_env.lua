-- -----------------------------------------------------------------------------
-- Init
-- -----------------------------------------------------------------------------

local _env = {
  Newline = string.byte('\n'),
  Dot = string.byte('.'),
  Alpha = {},
  Digits = {},
  Hex = {},
}

for key, value in pairs(_G) do
  if _env[key] == nil then
    _env[key] = value
  end
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
  Digits[byte] = true
  Hex[byte] = true
end
for byte = string.byte('A'), string.byte('F') do
  Hex[byte] = true
  Alpha[byte] = true
end
for byte = string.byte('G'), string.byte('Z') do
  Alpha[byte] = true
end
for byte = string.byte('a'), string.byte('f') do
  Hex[byte] = true
  Alpha[byte] = true
end
for byte = string.byte('g'), string.byte('z') do
  Alpha[byte] = true
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return { load = load }
