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

function _.pack(...)
  return supertable({ ... }):filter(function(s)
    -- Do not pack empty strings from zero capture matches
    return type(s) ~= 'string' or #s > 0
  end)
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
    return destructure.destructs:reduce(function(names, destruct)
      return type(destruct.nested) == 'table'
        and names:push(extractNames(destruct.nested):unpack())
        or names:push(destruct.name)
    end, supertable())
  end

  local function bodyCompiler(destructure, exprName)
    local compileParts = supertable()
    local arrayDestructCounter = 1

    destructure.destructs:each(function(destruct)
      local destructExprName = destruct.nested and _.newTmpName() or destruct.name

      compileParts:push(('%s%s = %s%s'):format(
        destruct.nested and 'local ' or '',
        destructExprName,
        exprName,
        destruct.keyed and '.'..destruct.name or '['..arrayDestructCounter..']'
      ))

      if destruct.default then
        compileParts:push((' if %s == nil then %s = %s end'):format(
          destructExprName,
          destructExprName,
          destruct.default
        ))
      end

      if destruct.nested then
        compileParts:push(bodyCompiler(destruct.nested, destructExprName))
      end

      if not destruct.keyed then
        arrayDestructCounter = arrayDestructCounter + 1
      end
    end)

    if destructure.opt then
      compileParts:insert(1, 'if '..exprName..' ~= nil then')
      compileParts:push('end')
    end

    return compileParts:join(' ')
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
