local state = require('erde.state')
local supertable = require('erde.supertable')
local inspect = require('inspect')
local lpeg = require('lpeg')

lpeg.locale(lpeg)
local _ = supertable(lpeg)

-- -----------------------------------------------------------------------------
-- Parser Helpers
-- -----------------------------------------------------------------------------

function _.CV(rule)
  return _.C(_.V(rule))
end

function _.CsV(rule)
  return _.Cs(_.V(rule))
end

function _.Pad(pattern)
  return _.V('Space') * pattern * _.V('Space')
end

function _.PadC(pattern)
  return _.V('Space') * _.C(pattern) * _.V('Space')
end

function _.PadCs(pattern)
  return _.V('Space') * _.Cs(pattern) * _.V('Space')
end

function _.Sum(patterns)
  return supertable(patterns):reduce(function(sum, pattern)
    return sum + pattern
  end, _.P(false))
end

function _.Product(patterns)
  return supertable(patterns):reduce(function(product, pattern)
    return product * pattern
  end, _.P(true))
end

function _.List(pattern, config)
  config = config or {}
  local minlen = config.minlen or 0

  local sep = _.Pad(config.sep or ',')
  local chainbase = sep * pattern
  local chain = chainbase ^ math.max(0, minlen - 1)

  if config.maxlen == 0 then
    return _.V('Space')
  elseif config.maxlen then
    chain = chain - chainbase ^ math.max(0, config.maxlen)
  end

  return (
    _.Product({
      pattern,
      chain,
      config.trailing == false and _.P(true) or sep ^ -1,
    }) + (minlen == 0 and _.V('Space') or _.P(false))
  ) / _.pack
end

function _.Expect(pattern)
  return pattern + _.Cc('__ERDE_ERROR__') * _.Cp() / function(capture, position)
    if capture == '__ERDE_ERROR__' then
      error(('Line %s, Column %s: Error'):format(
        _.currentline,
        position - _.currentlinestart
      ))
    else
      return capture
    end
  end
end

-- -----------------------------------------------------------------------------
-- Compiler Helpers
-- -----------------------------------------------------------------------------

function _.newtmpname()
  state.tmpnamecounter = state.tmpnamecounter + 1
  return ('__ERDE_TMP_%d__'):format(state.tmpnamecounter)
end

function _.echo(...)
  return ...
end

function _.concat(sep)
  return function(...)
    return supertable({ ... })
      :filter(function(v) return type(v) == 'string' end)
      :join(sep)
  end
end

function _.pack(...)
  return supertable({ ... })
end

function _.template(str)
  return function(...)
    return supertable({ ... }):reduce(function(compiled, v, i)
      return compiled:gsub('%%'..i, v)
    end, str)
  end
end

function _.iife(str)
  return _.template(('(function() %s end)()'):format(str))
end

function _.map(...)
  local keys = { ... }
  return function(...)
    return supertable({ ... }):map(function(value, i)
      if type(value) == 'table' then
        return supertable(value), keys[i]
      else
        return value, keys[i]
      end
    end)
  end
end

function _.indexchain(bodycompiler, optbodycompiler)
  return function(base, chain, ...)
    local chainexpr = supertable({ base }, chain:map(function(index)
      if index.variant == 1 then
        return '.'..index.value
      elseif index.variant == 2 then
        return '['..index.value..']'
      elseif index.variant == 3 then
        return '('..index.value:join(',')..')'
      elseif index.variant == 4 then
        return ':'..index.value
      end
    end)):join()

    if not chain:find(function(index) return index.opt end) then
      return bodycompiler(chainexpr, ...)
    else
      local prebody = chain:reduce(function(prebody, index)
        return {
          partialchain = prebody.partialchain .. index.suffix,
          parts = not index.opt and prebody.parts or
            prebody.parts:push(('if %s == nil then return end')
              :format(prebody.partialchain)),
        }
      end, { partialchain = base, parts = supertable() })

      return ('(function() %s %s end)()'):format(
        prebody.parts:join(' '),
        (optbodycompiler or bodycompiler)(chainexpr, ...)
      )
    end
  end
end

function _.compiledestructure(islocal, destructure, expr)
  local function extractnames(destructure)
    return destructure:reduce(function(names, destruct)
      return destruct.nested == false
        and names:push(destruct.name)
        or names:push(unpack(extractnames(destruct.nested)))
    end, supertable())
  end

  local function bodycompiler(destructure, exprname)
    return destructure
      :map(function(destruct)
        local destructexpr = exprname .. destruct.index
        local destructexprname = destruct.nested and _.newtmpname() or destruct.name
        return supertable({
          ('%s%s = %s'):format(
            destruct.nested and 'local ' or '',
            destructexprname,
            destructexpr
          ),
          destruct.default and
            ('if %s == nil then %s = %s end')
              :format(destructexprname, destructexprname, destruct.default),
          destruct.nested and
            bodycompiler(destruct.nested, destructexprname),
        })
          :filter(function(compiled) return compiled end)
          :join(' ')
      end)
      :join(' ')
  end

  local exprname = _.newtmpname()
  return ('%s%s do %s %s end'):format(
    islocal and 'local ' or '',
    extractnames(destructure):join(','),
    ('local %s = %s'):format(exprname, expr),
    bodycompiler(destructure, exprname)
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return _
