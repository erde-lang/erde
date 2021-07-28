local _ = {}

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

return _
