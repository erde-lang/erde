local _ = require('utils.underscore')

-- -----------------------------------------------------------------------------
-- Atoms
-- -----------------------------------------------------------------------------

local atoms = {
  Interpolation = function(node)
  end,

  LongString = function(node)
  end,
}

-- -----------------------------------------------------------------------------
-- Molecules
-- -----------------------------------------------------------------------------

local molecules = {}

-- -----------------------------------------------------------------------------
-- Organisms
-- -----------------------------------------------------------------------------

local organisms = {
  Declaration = function(isLocal, id, expr)
    return {
      compiled = ('%s%s%s'):format(
        isLocal and 'local ' or '',
        id.capture,
        expr and (' = %s'):format(expr.capture) or ''
      ),
      pretty = '',
    }
  end,
}

-- -----------------------------------------------------------------------------
-- Compiler
-- -----------------------------------------------------------------------------

local compiler = _.merge({
  atoms,
  molecules,
  organisms,
})

local function compile(node)
  return type(compiler[node.rule]) ~= 'function' and '' or compiler[node.rule](unpack(_.map(node, function(subnode)
    return compile(subnode)
  end, ipairs)))
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return compile
