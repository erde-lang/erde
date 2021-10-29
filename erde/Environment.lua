-- -----------------------------------------------------------------------------
-- Environment
-- -----------------------------------------------------------------------------

local Environment = {}

function Environment:addReference(t)
  for key, value in pairs(t) do
    self._reference[key] = value
  end
end

function Environment:load()
  if _VERSION:find('5.1') then
    setfenv(2, self)
  end
  return self
end

-- -----------------------------------------------------------------------------
-- EnvironmentMT
-- -----------------------------------------------------------------------------

local EnvironmentMT = {
  __index = function(self, key)
    if self._env[key] ~= nil then
      return self._env[key]
    elseif Environment[key] ~= nil then
      return Environment[key]
    else
      return self._reference[key]
    end
  end,
}

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return function()
  return setmetatable({
    _env = {},
    _reference = {},
  }, EnvironmentMT)
end
