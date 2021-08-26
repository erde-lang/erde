local inspect = require('inspect')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local state = {
  tmpcounter = 0,
  concatcache = {},
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
  sep = sep or ''
  if state.concatcache[sep] == nil then
    state.concatcache[sep] = function(...)
      return supertable({ ... })
        :filter(function(v) return type(v) == 'string' end)
        :join(sep)
    end
  end
  return state.concatcache[sep]
end

local function template(str)
  return function(...)
    return str:format(...)
  end
end

local function pack(...)
  return supertable({ ... })
end

local function map(...)
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

-- -----------------------------------------------------------------------------
-- Rule Helpers
-- -----------------------------------------------------------------------------

local function compiledestructure(islocal, destructure, expr)
  local function extractids(destructure)
    return destructure:reduce(function(ids, destruct)
      return destruct.nested == false
        and ids:push(destruct.id)
        or ids:push(unpack(extractids(destruct.nested)))
    end, supertable())
  end

  local function compilebody(destructure, exprid)
    return destructure
      :map(function(destruct)
        local destructexpr = exprid .. destruct.index
        local destructexprid = destruct.nested and newtmpid() or destruct.id
        return supertable({
          ('%s%s = %s'):format(
            destruct.nested and 'local ' or '',
            destructexprid,
            destructexpr
          ),
          destruct.default and
            ('if %s == nil then %s = %s end')
              :format(destructexprid, destructexprid, destruct.default),
          destruct.nested and
            compilebody(destruct.nested, destructexprid),
        })
          :filter(function(compiled) return compiled end)
          :join(' ')
      end)
      :join(' ')
  end

  local exprid = newtmpid()
  return ('%s%s do %s %s end'):format(
    islocal and 'local ' or '',
    extractids(destructure):join(','),
    ('local %s = %s'):format(exprid, expr),
    compilebody(destructure, exprid)
  )
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
  StringTableKey = template('[ %s ]'),
  MapTableField = template('%s = %s'),
  InlineTableField = function(id) return ('%s = %s'):format(id, id) end,
  TableField = echo,
  TableFieldList = concat(),
  Table = concat(),

  DotIndex = concat(),
  BracketIndex = concat(),
  ChainIndex = concat(),
  IndexExpr = echo,

  Destruct = map('keyed', 'id', 'nested', 'default'),
  Destructure = function(...)
    local keycounter = 1
    return supertable({ ... }):each(function(destruct)
      if destruct.keyed then
        destruct.index = ('.%s'):format(destruct.id)
      else
        destruct.index = ('[%d]'):format(keycounter)
        keycounter = keycounter + 1
      end
    end)
  end,
}

local Functions = {
  Arg = function(arg)
    if type(arg) == 'string' then
      return { id = arg, prebody = false }
    else
      local tmpid = newtmpid()
      return { id = tmpid, prebody = compiledestructure(true, arg, tmpid) }
    end
  end,

  OptArg = function(arg, expr)
    local optprebody = ('if %s == nil then %s = %s end'):format(arg.id, arg.id, expr)
    return {
      id = arg.id,
      prebody = arg.prebody
        and ('%s %s'):format(optprebody, arg.prebody)
        or optprebody,
    }
  end,

  VarArgs = function(id)
    return {
      id = id,
      prebody = ('local %s = {...}'):format(id),
      varargs = true,
    }
  end,

  ArgList = echo,
  OptArgList = echo,
  Params = pack,

  FunctionBody = echo,
  SkinnyFunction = echo,
  FatFunction = echo,
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
      :filter(function(param) return param.prebody end)
      :map(function(param) return param.prebody end)
      :join(' ')

    return ('function(%s) %s %s end'):format(ids, prebody, body)
  end,

  FunctionCallArgList = concat(','),
  FunctionCallParams = concat(),

  FunctionCallBase = concat(),
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
  Neq = concat('~='),
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
    local tmpid = newtmpid()
    return ([[(function()
      local %s = %s
      if %s ~= nil then
        return %s
      else
        return %s
      end
    )()]]):format(tmpid, default, tmpid, tmpid, backup)
  end,
}

local Declaration = {
  IdDeclaration = concat(' '),
  VarArgsDeclaration = function(islocal, id, expr)
    return ('%s%s = { %s }'):format(islocal and 'local ' or '', id, expr)
  end,
  DestructureDeclaration = compiledestructure,
  Declaration = echo,
}

local Blocks = {
  Block = concat('\n'),
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
