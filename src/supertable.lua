local inspect = require('inspect')

-- -----------------------------------------------------------------------------
-- Supertable
-- -----------------------------------------------------------------------------

local supertable = {}

function constructor(...)
  local t = {}
  for _, init in ipairs({ ... }) do
    if type(init) == 'table' then
      for key, value in pairs(init) do
        t[type(key) == 'string' and key or #t + 1] = value
      end
    end
  end
  return setmetatable(t, { __index = supertable })
end

-- -----------------------------------------------------------------------------
-- New Supertable Constructions
-- -----------------------------------------------------------------------------

function supertable:ipairs()
  local t = constructor()
  for _, value in ipairs(self) do
    table.insert(t, value)
  end
  return t
end

function supertable:kpairs()
  local t = constructor()
  for key, value in pairs(self) do
    if type(key) == 'string' then
      t[key] = value
    end
  end
  return t
end

function supertable:keys()
  local t = constructor()
  for key, _ in pairs(self) do
    if type(key) == 'string' then
      table.insert(t, key)
    end
  end
  return t
end

function supertable:values()
  local t = constructor()
  for _, value in pairs(self) do
    table.insert(t, value)
  end
  return t
end

-- -----------------------------------------------------------------------------
-- Loops
-- -----------------------------------------------------------------------------

function supertable:each(f)
  for key, value in pairs(self) do
    f(value, key)
  end
  return self
end

function supertable:map(fn)
  local t = constructor()
  for key, value in pairs(self) do
    local newValue, newKey = fn(value, key)
    t[newKey or (type(key) == 'string' and key or #t + 1)] = newValue
  end
  return t
end

function supertable:filter(fn)
  local t = constructor()
  for key, value in pairs(self) do
    if fn(value, key) then
      t[type(key) == 'string' and key or #t + 1] = value
    end
  end
  return t
end

function supertable:reduce(fn, accumulator)
  for key, value in pairs(self) do
    accumulator = fn(accumulator, value, key)
  end
  return accumulator
end

-- -----------------------------------------------------------------------------
-- Array Methods
-- -----------------------------------------------------------------------------

function supertable:insert(index, ...)
  for i, value in ipairs({ ... }) do
    table.insert(self, index + i - 1, value)
  end
  return self
end

function supertable:push(...)
  for _, value in ipairs({ ... }) do
    table.insert(self, value)
  end
  return self
end

function supertable:pop(n)
  local removed = {}
  for i = 1, n or 1 do
    table.insert(removed, table.remove(self))
  end
  return self, unpack(removed)
end

function supertable:remove(index, n)
  local removed = {}
  for _ = 1, n or 1 do
    table.insert(removed, table.remove(self, index))
  end
  return self, unpack(removed)
end

-- -----------------------------------------------------------------------------
-- Misc
-- -----------------------------------------------------------------------------

function supertable:join(sep)
  return table.concat(self, sep)
end

function supertable:find(target)
  local fn = type(target) == 'function' and target
    or function(value)
      return value == target
    end
  for key, value in pairs(self) do
    if fn(value, key) then
      return value, key
    end
  end
  return nil, nil
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return constructor