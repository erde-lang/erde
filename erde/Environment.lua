-- -----------------------------------------------------------------------------
-- Environment
-- -----------------------------------------------------------------------------

local Environment = setmetatable({}, {
  __call = function(self)
    return setmetatable({ _ENV = {} }, { __index = self })
  end,
})

-- -----------------------------------------------------------------------------
-- Methods
-- -----------------------------------------------------------------------------

function Environment:merge(t)
  for key, value in pairs(t) do
    if self._ENV[key] == nil then
      self._ENV[key] = value
    end
  end
end

function Environment:load()
  if _VERSION:find('5.1') then
    setfenv(2, self._ENV)
  else
    return self._ENV
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Environment
