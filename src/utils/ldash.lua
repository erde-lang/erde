return {
  Map = function(t, fn)
    local mapped = {}
    for i, v in ipairs(t) do
      table.insert(mapped, fn(v, i))
    end
    return mapped
  end,

  Reduce = function(t, fn, init)
    local reduced = init
    for i, v in ipairs(t) do
      reduced = fn(reduced, v, i)
    end
    return reduced
  end,

  Join = function(t, sep)
    sep = sep or ''
    local joined = t[1]
    for i = 2, #t do
      joined = joined .. sep .. t[i]
    end
    return joined
  end,
}
