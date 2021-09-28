local state = require('erde.state')
local supertable = require('erde.supertable')
local inspect = require('inspect')
local lpeg = require('lpeg')

lpeg.locale(lpeg)
local _ = supertable(lpeg)

-- -----------------------------------------------------------------------------
-- Parser Helpers
-- -----------------------------------------------------------------------------

function _.CsV(rule)
  return _.Cs(_.V(rule))
end

function _.Pad(pattern)
  return _.V('Space') * pattern * _.V('Space')
end

function _.PadC(pattern)
  return _.V('Space') * _.C(pattern) * _.V('Space')
end

function _.Parens(pattern)
  return _.Pad('(') * pattern * _.Pad(')')
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
  local minLen = config.minLen or 0

  local sep = _.Pad(config.sep or ',')
  local chainBase = sep * pattern
  local chain = chainBase ^ math.max(0, minLen - 1)

  if config.maxLen == 0 then
    return _.V('Space')
  elseif config.maxLen then
    chain = chain - chainBase ^ config.maxLen
  end

  return (
    _.Product({
      pattern,
      chain,
      config.trailing == false and _.P(true) or sep ^ -1,
    }) + (minLen == 0 and _.V('Space') or _.P(false))
  ) / _.pack
end

function _.Expect(pattern)
  return pattern + _.Cc('__ERDE_ERROR__') * _.Cp() / function(capture, position)
    if capture == '__ERDE_ERROR__' then
      error(('Line %s, Column %s: Error'):format(
        state.currentLine,
        position - state.currentLineStart
      ))
    else
      return capture
    end
  end
end

-- -----------------------------------------------------------------------------
-- Compiler Helpers
-- -----------------------------------------------------------------------------

function _.newTmpName()
  state.tmpNameCounter = state.tmpNameCounter + 1
  return ('__ERDE_TMP_%d__'):format(state.tmpNameCounter)
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
  return supertable({ ... }):filter(function(s)
    -- Do not pack empty strings from zero capture matches
    return type(s) ~= 'string' or #s > 0
  end)
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

function _.indexChain(bodyCompiler, optBodyCompiler)
  return function(base, chain, ...)
    local chainExpr = supertable({ base }, chain:map(function(index)
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
      return bodyCompiler(chainExpr, ...)
    else
      local prebody = chain:reduce(function(prebody, index)
        return {
          partialChain = prebody.partialChain .. index.suffix,
          parts = not index.opt and prebody.parts or
            prebody.parts:push(('if %s == nil then return end')
              :format(prebody.partialChain)),
        }
      end, { partialChain = base, parts = supertable() })

      return ('(function() %s %s end)()'):format(
        prebody.parts:join(' '),
        (optBodyCompiler or bodyCompiler)(chainExpr, ...)
      )
    end
  end
end

function _.compileDestructure(isLocal, destructure, expr)
  local function extractNames(destructure)
    return destructure:reduce(function(names, destruct)
      return destruct.nested == false
        and names:push(destruct.name)
        or names:push(unpack(extractNames(destruct.nested)))
    end, supertable())
  end

  local function bodyCompiler(destructure, exprName)
    return destructure
      :map(function(destruct)
        local destructExpr = exprName .. destruct.index
        local destructExprName = destruct.nested and _.newTmpName() or destruct.name
        return supertable({
          ('%s%s = %s'):format(
            destruct.nested and 'local ' or '',
            destructExprName,
            destructExpr
          ),
          destruct.default and
            ('if %s == nil then %s = %s end')
              :format(destructExprName, destructExprName, destruct.default),
          destruct.nested and
            bodyCompiler(destruct.nested, destructExprName),
        })
          :filter(function(compiled) return compiled end)
          :join(' ')
      end)
      :join(' ')
  end

  local exprName = _.newTmpName()
  return ('%s%s do %s %s end'):format(
    isLocal and 'local ' or '',
    extractNames(destructure):join(','),
    ('local %s = %s'):format(exprName, expr),
    bodyCompiler(destructure, exprName)
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return _
