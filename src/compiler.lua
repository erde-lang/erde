local inspect = require('inspect')
local _ = require('utils.underscore')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

function isnode(node)
  return type(node) == 'table' and type(node.rule) == 'string'
end

function echo(value)
  return value
end

-- -----------------------------------------------------------------------------
-- Atoms
-- -----------------------------------------------------------------------------

local atoms = {
  Id = echo,
  Number = echo,
  String = echo,

  Keyword = function(node)
  end,

  Interpolation = function(node)
  end,

  LongString = function(node)
  end,
}

-- -----------------------------------------------------------------------------
-- Molecules
-- -----------------------------------------------------------------------------

local molecules = {
  Expr = echo,
}

-- -----------------------------------------------------------------------------
-- Organisms
-- -----------------------------------------------------------------------------

local organisms = {
  Kale = echo,
  Block = function(...)
    return _.join({...}, '\n')
  end,
  Statement = echo,
  Declaration = function(isLocal, id, expr)
    return ('%s%s%s'):format(
      #isLocal > 0 and 'local ' or '',
      id,
      expr and (' = %s'):format(expr) or ''
    )
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
  if not isnode(node) then
    return subnode
  elseif type(compiler[node.rule]) ~= 'function' then
    error('No compiler for rule: ' .. node.rule)
  else
    return compiler[node.rule](unpack(_.map(node, function(subnode)
      return isnode(subnode) and compile(subnode) or subnode
    end, ipairs)))
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return compile
