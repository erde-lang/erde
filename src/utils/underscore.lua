local _ = {}

-- -----------------------------------------------------------------------------
-- Iterators
-- -----------------------------------------------------------------------------

function _.pairs(t)
  return pairs(t)
end

function _.kpairs(t)
  -- pairs always iterates through number indices first. Since pairs is a
  -- stateless iterator, we can simply "start from there"
  return next, t, #t
end

function _.ipairs(t)
  return ipairs(t)
end

-- -----------------------------------------------------------------------------
-- ipairs
-- -----------------------------------------------------------------------------

function _.insert(t, idx, ...)
  local varargs = { ... }

  if #varargs == 0 then
    varargs = { idx }
    idx = #t + 1
  else
    idx = idx < 0 and idx + #t + 1 or idx
  end

  for i, v in ipairs(varargs) do
    table.insert(t, idx + (i - 1), v)
  end

  return t
end

function _.remove(t, idx, n)
  local removed = {}

  idx = idx and (idx < 0 and idx + #t + 1 or idx) or #t
  n = n or 1

  for i = 1, n do
    _.insert(removed, table.remove(t, idx))
  end

  return unpack(removed)
end

function _.join(t, sep)
  sep = sep or ''
  local joined = ''

  for i, v in ipairs(t) do
    joined = joined .. tostring(v) .. (i < #t and sep or '')
  end

  return joined
end

function _.slice(t, istart, iend)
  local sliced = {}

  istart = istart < 0 and istart + #t + 1 or istart
  iend = iend and (iend < 0 and iend + #t + 1 or iend) or #t

  for i = istart, iend do
    table.insert(sliced, t[i])
  end

  return sliced
end

function _.has(t, value)
  for i, v in ipairs(t) do
    if v == value then
      return true
    end
  end

  return false
end

-- -----------------------------------------------------------------------------
-- kpairs
-- -----------------------------------------------------------------------------

function _.keys(t)
  local keys = {}

  for k, v in _.kpairs(t) do
    table.insert(keys, k)
  end

  return keys
end

-- -----------------------------------------------------------------------------
-- pairs
-- -----------------------------------------------------------------------------

function _.values(t, iter)
  iter = iter or pairs
  local values = {}

  for k, v in iter(t) do
    table.insert(values, v)
  end

  return values
end

function _.each(t, f, iter)
  iter = iter or pairs

  for a, v in iter(t) do
    f(v, a)
  end
end

function _.map(t, f, iter)
  iter = iter or pairs
  local mapped = {}

  for a, v in iter(t) do
    local mapV, mapA = f(v, a)

    if mapA == nil then
      if type(a) == 'number' then
        table.insert(mapped, mapV)
      else
        mapped[a] = mapV
      end
    end
  end

  return mapped
end

function _.filter(t, f, iter)
  iter = iter or pairs
  local filtered = {}

  for a, v in iter(t) do
    if f(v, a) then
      if type(a) == 'number' then
        table.insert(filtered, v)
      else
        filtered[a] = v
      end
    end
  end

  return filtered
end

function _.reduce(t, f, accumulator, iter)
  iter = iter or pairs

  for a, v in iter(t) do
    accumulator = f(accumulator, v, a)
  end

  return accumulator
end

function _.find(t, value, iter)
  iter = iter or pairs

  local f = type(value) == 'function' and value
    or function(v)
      return v == value
    end

  for a, v in iter(t) do
    if f(v, a) then
      return v, a
    end
  end

  return nil, nil
end

function _.merge(tables, iter)
  iter = iter or pairs
  local merged = {}

  if type(tables[#tables]) == 'function' then
    iter = table.remove(tables)
  end

  for i, t in ipairs(tables) do
    for a, v in iter(t) do
      if type(a) == 'number' then
        table.insert(merged, v)
      else
        merged[a] = v
      end
    end
  end

  return merged
end

-- -----------------------------------------------------------------------------
-- Strings
-- -----------------------------------------------------------------------------

function _.split(s, sep)
  sep = sep or '%s'
  local parts = {}

  for match in s:gmatch('([^' .. sep .. ']+)') do
    table.insert(parts, match)
  end

  return parts
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return _
