local inspect = require('inspect')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local state = {
  tmpcounter = 1,
}

local function newtmpid()
  state.tmpcounter = state.tmpcounter + 1
  return ('__ORBIT_TMP_%d__'):format(state.tmpcounter)
end

-- -----------------------------------------------------------------------------
-- Compile Helpers
-- -----------------------------------------------------------------------------

local function noop()
end

local function echo(...)
  return ...
end

local function concat(sep)
  return function(...)
    return table.concat({...}, sep)
  end
end

local function template(str)
  return function(...)
    return str:format(...)
  end
end

local function pack(...)
  return supertable({ ... })
end

-- -----------------------------------------------------------------------------
-- Rule Sets
-- -----------------------------------------------------------------------------

local Core = {
  Id = echo,
  Keyword = noop,
  Bool = echo,

  SingleLineComment = noop,
  MultiLineComment = noop,
  Comment = noop,
}

local Numbers = {
  Number = echo,
}

local Strings = {
  EscapedChar = echo,

  Interpolation = function(value)
    return {
      interpolation = true,
      value = ('tostring(%s)'):format(value),
    }
  end,

  -- TODO make sure the string doesn't use [==[. Should almost never happen but
  -- need to account for it nonetheless
  -- Maybe can simply wrap in "" and escape inner "? Need to check newlines.
  LongString = function(...)
    return ('[==[%s]==]'):format(supertable({ ... })
      :map(function(v)
        return v.interpolation
          and (']==]..%s..[==['):format(v.value)
          or v
      end)
      :join()
    )
  end,

  String = echo,
}

local Tables = {
  StringTableKey = template('[%s]'),
  MapTableField = template('%s = %s'),
  InlineTableField = function(id) return ('%s = %s'):format(id, id) end,
  TableField = echo,
  Table = function(...) return ('{ %s }'):format(supertable({ ... }):join(', ')) end,

  ArrayDestructure = pack,
  MapDestructure = pack,
}

local Functions = {
  Arg = function(id) return { id = id } end,
  OptArg = function(id, expr) return { id = id, default = expr } end,
  VarArgs = function(id) return { id = id, varargs = true } end,

  ArgList = echo,
  OptArgList = echo,
  Params = pack,

  FunctionBody = echo,
  SkinnyFunction = function(...) return false, ... end,
  FatFunction = function(...) return true, ... end,
  Function = function(fat, params, body)
    if body == nil then
      return ('function(%s) %s end'):format(fat and 'self' or '', params)
    end

    local varargs = params[#params].varargs and params:pop()

    local ids = supertable(
      fat and { 'self' },
      params:map(function(param) return param.id end),
      varargs and { '...' }
    ):join(',')

    local prebody = params
      :filter(function(param) return param.default end)
      :map(function(param)
        return ('if %s == nil then %s = %s end')
          :format(param.id, param.id, param.default)
        end)
      :push(varargs and ('local %s = {...}'):format(varargs.id) or nil)
      :join(' ')

    return ('function(%s) %s %s end'):format(ids, prebody, body)
  end,

  FunctionCallArgList = concat(','),
  FunctionCallParams = concat(),

  ExprCall = concat(),
  SkinnyFunctionCall = concat(),
  FatFunctionCall = concat(),
  FunctionCall = echo,
}

local LogicFlow = {
  If = template('if %s then %s'),
  ElseIf = template('elseif %s then %s'),
  Else = template('else %s'),
  IfElse = function(...)
    return supertable({ ... }, { 'end' }):join(' ')
  end,

  Return = concat(' '),
}

local Expressions = {
  AtomExpr = echo,
  MoleculeExpr = echo,
  OrganismExpr = echo,
  Expr = echo,

  IndexableExpr = concat(),
  DotIndexExpr = concat(),
  BracketIndexExpr = concat(),
  IndexExpr = echo,
}

local Operators = {
  And = concat('and'),
  Or = concat('or'),

  Addition = concat('+'),
  Subtraction = concat('-'),
  Multiplication = concat('*'),
  Division = concat('/'),
  Modulo = concat('%'),

  Greater = concat('>'),
  Less = concat('<'),
  GreaterEq = concat('>='),
  LessEq = concat('<='),
  Eq = concat('=='),

  Binop = echo,

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
    local __ORBIT_TMP__ = %s
    if __ORBIT_TMP__ ~= nil then return __ORBIT_TMP__ else return %s end
    )()
    ]]):format(default, backup)
  end,
}

local Declaration = {
  IdDeclaration = concat(' '),

  ArrayDestructureDeclaration = function(isLocal, ids, expr) 
    local tmpid = newtmpid()
    return supertable(
      { ('local %s = %s'):format(tmpid, expr) }, 
      ids:map(function(id, index)
        return (isLocal and 'local %s = %s[%d]' or '%s = %s[%d]')
          :format(id, tmpid, index)
      end)
    ):join('\n')
  end,

  MapDestructureDeclaration = function(isLocal, ids, expr)
    local tmpid = newtmpid()
    return supertable(
      { ('local %s = %s'):format(tmpid, expr) }, 
      ids:map(function(id)
        return (isLocal and 'local %s = %s.%s' or '%s = %s.%s')
          :format(id, tmpid, id)
      end)
    ):join('\n')
  end,

  Declaration = echo,
}

local Blocks = {
  Block = function(...)
    return supertable({ ... }):join('\n')
  end,
  Statement = echo,
}

-- -----------------------------------------------------------------------------
-- Compiler
-- -----------------------------------------------------------------------------

local compiler = supertable(
  Blocks,
  Declaration,
  Operators,
  Expressions,
  LogicFlow,
  Functions,
  Tables,
  Strings,
  Numbers,
  Core
)

local function isnode(node)
  return type(node) == 'table' and type(node.rule) == 'string'
end

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
