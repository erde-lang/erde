local inspect = require('inspect')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

function isnode(node)
  return type(node) == 'table' and type(node.rule) == 'string'
end

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
  Keyword = function() end,
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
    local interpolate = function(v)
      return type(v) == 'string' and v or (']==]..%s..[==['):format(v.value)
    end
    return ('[==[%s]==]'):format(supertable({ ... }):map(interpolate):join(''))
  end,

  String = echo,

  --
  -- Table
  --

  TableStringField = function(expr) return ('[%s]'):format(expr) end,
  TableField = function(key, value) return ('%s = %s'):format(key, value) end,
  Table = function(...) return ('{ %s }'):format(supertable({ ... }):join(', ')) end,

  --
  -- Functions
  --

  Arg = function(id) return { id = id } end,
  OptArg = function(id, expr) return { id = id, default = expr } end,
  VarArgs = function(id) return { id = id, varargs = true } end,

  ArgList = echo,
  OptArgList = echo,
  Parameters = function(...) return { ... } end,

  FunctionBody = echo,
  SkinnyFunction = function(...) return false, ... end,
  FatFunction = function(...) return true, ... end,
  Function = function(fat, params, body)
    if body == nil then
      return ('function(%s) %s end'):format(fat and 'self' or '', params)
    end

    local varargs = params[#params].varargs and table.remove(params)

    local ids = supertable(
      fat and { 'self' },
      supertable(params):map(function(param) return param.id end),
      varargs and { '...' }
    ):join(',')

    local prebody = supertable(params)
      :filter(function(param) return param.default end)
      :map(function(param)
        return ('if %s == nil then %s = %s end')
          :format(param.id, param.id, param.default)
        end)
      :push(varargs and ('local %s = {...}'):format(varargs.id) or nil)
      :join(' ')

    return ('function(%s) %s %s end'):format(ids, prebody, body)
  end,
}

-- -----------------------------------------------------------------------------
-- Molecules
-- -----------------------------------------------------------------------------

local molecules = {
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

  IfElse = function(...)
    return supertable({ ... }, { 'end' }):join(' ')
  end,

  Return = function(expr)
    return ('return %s'):format(expr or '')
  end,

  --
  -- Expressions
  --

  NumberExpr = echo,
  StringExpr = echo,
  LiteralExpr = echo,
  Expr = echo,

  --
  -- Operators
  --

  And = function(lhs, rhs) return ('%s and %s'):format(lhs, rhs) end,
  Or = function(lhs, rhs) return ('%s or %s'):format(lhs, rhs) end,
  AdditionCore = function(...) return table.concat({...}, ' + ') end,
  Addition = echo,
  Subtraction = function(lhs, rhs) return ('%s - %s'):format(lhs, rhs) end,
  Multiplication = function(lhs, rhs) return ('%s * %s'):format(lhs, rhs) end,
  Division = function(lhs, rhs) return ('%s / %s'):format(lhs, rhs) end,
  Modulo = function(lhs, rhs) return ('%s %% %s'):format(lhs, rhs) end,
  Ternary = function(condition, iftrue, iffalse)
    return ('(function() if %s then return %s %s end)()'):format(
      condition,
      iftrue,
      iffalse and ('else return %s'):format(iffalse) or ''
    )
  end,
  NullCoalescence = function(default, backup)
    return ([[
      (function()
        local __KALE_TMP__ = %s
        if __KALE_TMP__ ~= nil then return __KALE_TMP__ else return %s end
      )()
    ]]):format(default, backup)
  end,
}

-- -----------------------------------------------------------------------------
-- Organisms
-- -----------------------------------------------------------------------------

local organisms = {
  Kale = echo,
  Block = function(...)
    return supertable({ ... }):join('\n')
  end,
  Statement = echo,

  ArrayDestructure = function(isLocal, ...)
    local ids = supertable({ ... })
    local _, expr = ids:pop()
    return ids:map(function(id, index)
      return ('%s%s = %s[%d]'):format(
        #isLocal > 0 and 'local ' or '',
        id,
        expr,
        index
      )
    end):join('\n')
  end,

  MapDestructure = function(isLocal, ...)
    local ids = supertable({ ... })
    local _, expr = ids:pop()
    return ids:map(function(id)
      return ('%s%s = %s.%s'):format(
        #isLocal > 0 and 'local ' or '',
        id,
        expr,
        id
      )
    end):join('\n')
  end,

  Declaration = function(isLocal, id, expr)
    return supertable({
      #isLocal > 0 and 'local ' or '',
      id,
      expr and (' = %s'):format(expr) or '',
    }):join('')
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
    return compiler[node.rule](unpack(node:ipairs():reduce(function(args, subnode)
      return args:push(unpack(isnode(subnode)
        and { compile(subnode) }
        or { subnode }
      ))
    end, supertable())))
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return compile
