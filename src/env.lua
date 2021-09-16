local inspect = require('inspect')
local lpeg = require('lpeg')
lpeg.locale(lpeg)
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- Env
--
-- The env is used for all of the rules. This prevents us from having to
-- constantly prefix / destructure all of our utilities and greatly reduces
-- noice.
-- -----------------------------------------------------------------------------

local env = setmetatable(
  supertable(lpeg)
    :filter(function(v, k) return _G[k] == nil end)
    :merge({
      currentline = 1,
      currentlinestart = 1,
      tmpnamecounter = 0,
    }),
  { __index = _G, __call = function(self) setfenv(2, self) end }
)

function env:reset()
  self.currentline = 1
  self.currentlinestart = 1
end

-- -----------------------------------------------------------------------------
-- Parser Helpers
-- -----------------------------------------------------------------------------

function env.CV(rule)
  return lpeg.C(lpeg.V(rule))
end

function env.Pad(pattern)
  return lpeg.V('Space') * pattern * lpeg.V('Space')
end

function env.PadC(pattern)
  return lpeg.V('Space') * lpeg.C(pattern) * lpeg.V('Space')
end

function env.Csv(pattern, commacapture)
  local comma = commacapture and env.PadC(',') or env.Pad(',')
  return pattern * (comma * pattern) ^ 0 * env.Pad(',') ^ -1
end

function env.Sum(patterns)
  return supertable(patterns):reduce(function(sum, pattern)
    return sum + pattern
  end, lpeg.P(false))
end

function env.Product(patterns)
  return supertable(patterns):reduce(function(product, pattern)
    return product * pattern
  end, lpeg.P(true))
end

function env.Demand(pattern)
  return pattern + lpeg.Cc('__ERDE_ERROR__') * lpeg.Cp() / function(capture, position)
    if capture == '__ERDE_ERROR__' then
      error(('Line %s, Column %s: Error'):format(
        env.currentline,
        position - env.currentlinestart
      ))
    else
      return capture
    end
  end
end

-- -----------------------------------------------------------------------------
-- Compiler Helpers
-- -----------------------------------------------------------------------------

function env.newtmpname()
  env.tmpnamecounter = env.tmpnamecounter + 1
  return ('__ERDE_TMP_%d__'):format(env.tmpnamecounter)
end

function env.echo(...)
  return ...
end

function env.concat(sep)
  return function(...)
    return supertable({ ... })
      :filter(function(v) return type(v) == 'string' end)
      :join(sep)
  end
end

function env.pack(...)
  return supertable({ ... })
end

function env.template(str)
  return function(...)
    return supertable({ ... }):reduce(function(compiled, v, i)
      return compiled:gsub('%%'..i, v)
    end, str)
  end
end

function env.iife(str)
  return env.template(('(function() %s end)()'):format(str))
end

function env.map(...)
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

function env.indexchain(bodycompiler)
  return function(base, chain, ...)
    print(base, inspect(chain))
    local chainexpr = supertable({ base }, chain:map(function(index)
      return index.suffix
    end)):join()

    if not chain:find(function(index) return index.optional end) then
      return chainexpr
    else
      local prebody = chain:reduce(function(prebody, index)
        return {
          partialchain = prebody.partialchain .. index.suffix,
          parts = not index.optional and prebody.parts or
            prebody.parts:push(('if %s == nil then return end'):format(prebody.partialchain)),
        }
      end, { partialchain = base, parts = supertable() })

      return ('(function() %s %s end)()'):format(
        prebody.parts:join(' '),
        bodycompiler(chainexpr, ...)
      )
    end
  end
end

function env.compiledestructure(islocal, destructure, expr)
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
        local destructexprname = destruct.nested and newtmpname() or destruct.name
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

  local exprname = newtmpname()
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

return env
