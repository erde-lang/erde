local inspect = require('inspect')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

function isnode(node)
  return type(node) == 'table' and type(node.rule) == 'string'
end

-- TODO: FIXME
function echo(...)
  return ...
end

-- -----------------------------------------------------------------------------
-- Atoms
-- -----------------------------------------------------------------------------

local atoms = {
  --
  -- Core
  --

  Id = echo,
  Keyword = function()
  end,
  Bool = echo,

  --
  -- Number
  --

  Number = echo,

  --
  -- Strings
  --

  EscapedChar = echo,

  Interpolation = function(value)
    return { value = ('tostring(%s)'):format(value) }
  end,

  -- TODO make sure the string doesn't use [==[. Should almost never happen but
  -- need to account for it nonetheless
  -- Maybe can simply wrap in "" and escape inner "? Need to check newlines.
  LongString = function(...)
    local interpolate = function(value)
      return type(v) == 'string' and v or (']==]..%s..[==['):format(v.value)
    end
    return ('[==[%s]==]'):format(supertable(...):map(interpolate):join(''))
  end,

  String = echo,

  --
  -- Functions
  --

  Arg = function(id)
    return { id = id }
  end,
  Args = echo,

  OptArg = function(id, expr)
    return { id = id, default = expr }
  end,
  OptArgs = echo,

  VarArgs = function(id)
    return { id = id, varargs = true }
  end,

  Parameters = function(...)
    return { ... }
  end,

  Function = function(params, body)
    if body == nil then
      return ('function() %s end'):format(params)
    end

    local varargs = params[#params].varargs and table.remove(params)

    -- TODO: supertables
    local ids = (function()
      local ids = params[1].id
      for i = 2, #params do
        ids = ids .. ',' .. params[i].id
      end
      return ids .. (varargs and ',...' or '')
    end)()

    local prebody = (function()
      local prebody = varargs and ('local %s = {...}'):format(varargs.id) or ''
      for i, param in ipairs(params) do
        if param.default then
          prebody = ('%s if %s == nil then %s = %s end'):format(
            prebody,
            param.id,
            param.id,
            param.default
          )
        end
      end
      return prebody
    end)()

    return ('function(%s) %s %s end'):format(ids, prebody, body)
  end,

  --
  -- Logic Flow
  --

  If = function(expr, block)
    return ('if %s then %s'):format(expr, block)
  end,

  ElseIf = function(expr, block)
    return ('elseif %s then %s'):format(expr, block)
  end,

  Else = function(block)
    return ('else %s'):format(block)
  end,

  IfStatement = function(...)
    return supertable(..., 'end'):join(' ')
  end,
}

-- -----------------------------------------------------------------------------
-- Molecules
-- -----------------------------------------------------------------------------

local molecules = {
  Literal = echo,
  Expr = echo,
}

-- -----------------------------------------------------------------------------
-- Organisms
-- -----------------------------------------------------------------------------

local organisms = {
  Kale = echo,
  Block = function(...)
    return supertable(...):join('\n')
  end,
  Statement = echo,
  Declaration = function(isLocal, id, expr)
    return supertable(
      #isLocal > 0 and 'local ' or '',
      id,
      expr and (' = %s'):format(expr) or ''
    ):join('')
  end,
}

-- -----------------------------------------------------------------------------
-- Compiler
-- -----------------------------------------------------------------------------

local compiler = supertable(atoms, molecules, organisms)

local function compile(node)
  if not isnode(node) then
    return subnode
  elseif type(compiler[node.rule]) ~= 'function' then
    error('No compiler for rule: ' .. node.rule)
  else
    return compiler[node.rule](node:ipairs():map(function(subnode)
      return isnode(subnode) and compile(subnode) or subnode
    end))
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return compile
