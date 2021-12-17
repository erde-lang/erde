-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

local erdestd = {}

-- -----------------------------------------------------------------------------
-- String Functions
-- -----------------------------------------------------------------------------

--- Split a string into a table.
-- @tparam string s the string to split
-- @tparam[opt="%s"] string sep the separator on which to split
-- @treturn table the table of split values
erdestd.split = {
  name = '__ERDESTD_SPLIT__',
  def = [[
    function __ERDESTD_SPLIT__(s, sep)
      sep = sep or '%s'
      local values = {}

      for match in s:gmatch('([^' .. sep .. ']+)') do
        table.insert(values, match)
      end

      return values
    end
  ]],
}

-- -----------------------------------------------------------------------------
-- Table Functions
-- -----------------------------------------------------------------------------

--- Create a table from the keys of another table's map elements.
-- @tparam table t the table from which to extract
-- @treturn table the table of keys
erdestd.keys = {
  name = '__ERDESTD_KEYS__',
  def = [[
    function __ERDESTD_KEYS__(t)
      local keys = {}

      for key, value in pairs(t) do
        if type(key) == 'string' then
          keys[#keys + 1] = key
        end
      end

      return keys
    end
  ]],
}

--- Create a table from the values of another table's map elements.
-- @tparam table t the table from which to extract
-- @treturn table the table of values
erdestd.values = {
  name = '__ERDESTD_VALUES__',
  def = [[
    function __ERDESTD_VALUES__(t)
      local values = {}

      for key, value in pairs(t) do
        if type(key) == 'string' then
          values[#values + 1] = value
        end
      end

      return values
    end
  ]],
}

--- Map the elements of a table to different values (and keys).
-- @tparam table t the table to map
-- @tparam function mapper callback to invoke. Takes (value, key) as params and
-- is expected to return at least one value (the mapped value) and optionally a
-- new key.
-- @treturn table the mapped table
erdestd.map = {
  name = '__ERDESTD_MAP__',
  def = [[
    function __ERDESTD_MAP__(t, mapper)
      local mapped = {}

      for key, value in pairs(t) do
        local mappedvalue, mappedkey = mapper(value, key)

        if mappedkey ~= nil then
          mapped[mappedkey] = mappedvalue
        elseif type(key) == 'string' then
          mapped[key] = mappedvalue
        else
          mapped[#mapped + 1] == mappedvalue
        end
      end

      return mapped
    end
  ]],
}

--- Filter the elements of a table.
-- @tparam table t the table to filter
-- @tparam function filterer callback to invoke. Takes (value, key) as params
-- and it expected to return either true (if the key, value pair should be kept)
-- or false (if the key, value pair should be discarded).
-- @treturn table the filtered table
erdestd.filter = {
  name = '__ERDESTD_FILTER__',
  def = [[
    function __ERDESTD_FILTER__(t, filterer)
      local filtered = {}

      for key, value in pairs(t) do
        if filterer(value, key) then
          if type(key) == 'string' then
            filtered[key] = value
          else
            filtered[#filtered + 1] = value
          end
        end
      end

      return filtered
    end
  ]],
}

--- Reduce the elements of a table to a single value.
-- @tparam table t the table to reduce
-- @tparam func reducer callback to invoke. Takes (reduction, value, key) as
-- params and is expected to return the reduction.
-- @param reduction the reduction's initial value
-- @return the reduction
erdestd.reduce = {
  name = '__ERDESTD_REDUCE__',
  def = [[
    function __ERDESTD_REDUCE__(t, reducer, reduction)
      for key, value in pairs(t) do
        reduction = reducer(reduction, value, key)
      end

      return reduction
    end
  ]],
}

--- Create a table from a consecutive subset of another table's array elements.
-- @tparam table t the table from which to extract
-- @tparam[opt=0] number istart starting index of the slice, can be negative
-- @tparam[opt=#t] number iend ending index of the slice, can be negative
-- @treturn table the table slice
erdestd.slice = {
  name = '__ERDESTD_SLICE__',
  def = [[
    function __ERDESTD_SLICE__(t, istart, iend)
      local sliced = {}

      if istart == nil then
        istart = 0
      elseif istart < 0 then
        istart = istart + #t + 1
      end

      if iend == nil then
        iend = #t
      elseif iend < 0 then
        iend = iend + #t + 1
      end

      for i = istart, iend do
        table.insert(sliced, t[i])
      end

      return sliced
    end
  ]],
}

--- Join the array elements of a table into a string.
-- @tparam table t the table to join
-- @tparam[opt=""] string sep optional separator
-- @treturn string the joined string
erdestd.join = {
  name = '__ERDESTD_JOIN__',
  def = [[
    function __ERDESTD_JOIN__(t, sep)
      sep = sep or ''
      local joined = ''

      for i, v in ipairs(t) do
        joined = joined .. tostring(v) .. (i < #t and sep or '')
      end

      return joined
    end
  ]],
}

--- Find a (value, key) pair in a table.
-- @tparam table t the table to search
-- @param search if this is a function, the first pair w/
-- `search(value, key) == true` is returned. Otherwise the first pair w/
-- `value === search` is returned. Default returns (nil, nil).
-- @treturn value the found value
-- @treturn key the found key
erdestd.find = {
  name = '__ERDESTD_FIND__',
  def = [[
    function __ERDESTD_FIND__(t, search)
      iter = iter or pairs

      if type(search) == 'function' then
        for key, value in pairs(t) do
          if search(value, key) then
            return value, key
          end
        end
      else
        for key, value in pairs(t) do
          if value == search then
            return value, key
          end
        end
      end

      return nil, nil
    end
  ]],
}

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return erdestd
