local inspect = require('inspect')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local state = {
  tmpcounter = 0,
}

local function newtmpid()
  state.tmpcounter = state.tmpcounter + 1
  return ('__ORBIT_TMP_%d__'):format(state.tmpcounter)
end

-- -----------------------------------------------------------------------------
-- Compile Helpers
-- -----------------------------------------------------------------------------

local function echo(...)
  return ...
end

local function concat(sep)
  return function(...)
    return supertable({ ... })
      :filter(function(v) return type(v) == 'string' end)
      :join(sep)
  end
end

local function template(str)
  return function(...)
    return supertable({ ... }):reduce(function(compiled, v, i)
      return compiled:gsub('%%'..i, v)
    end, str)
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
  IdExpr = concat(),
  Number = echo,
}

local Strings = {
  EscapedChar = echo,

  Interpolation = function(value)
    return { interpolation = true, value = value }
  end,

  LongString = function(...)
    local values = supertable({ ... })

    local eqstats = values:reduce(function(eqstats, char)
      return char ~= '='
        and { counter = 0, max = eqstats.max }
        or {
          counter = eqstats.counter + 1,
          max = math.max(eqstats.max, eqstats.counter + 1),
        }
    end, { counter = 0, max = 0 })

    local eqid = ('='):rep(eqstats.max + 1)

    return ('[%s[%s]%s]'):format(
      eqid,
      values:map(function(v)
        return v.interpolation
          and (']%s]..tostring(%s)..[%s['):format(eqid, v.value, eqid)
          or v
      end):join(),
      eqid
    )
  end,

  String = concat(),
}

local Tables = {
  StringTableKey = template('[ %1 ]'),
  MapTableField = template('%1 = %2'),
  InlineTableField = template('%1 = %1'),
  TableField = echo,
  Table = concat(),

  DotIndex = concat(),
  BracketIndex = concat(),
  IndexChain = concat(),
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
  Arg = function(isdestructure, arg)
    if isdestructure then
      local tmpid = newtmpid()
      return { id = tmpid, prebody = compiledestructure(true, arg, tmpid) }
    else
      return { id = arg, prebody = false }
    end
  end,
  OptArg = function(arg, expr)
    return {
      id = arg.id,
      prebody = supertable({
        ('if %s == nil then %s = %s end'):format(arg.id, arg.id, expr),
        arg.prebody,
      }):join(' '),
    }
  end,
  VarArgs = function(id)
    return {
      id = id,
      prebody = ('local %s = {...}'):format(id),
      varargs = true,
    }
  end,
  Params = pack,

  FunctionExprBody = template('return %1'),
  FunctionBody = echo,
  Function = function(needself, params, body)
    local varargs = params[#params]
      and params[#params].varargs
        and params:pop()

    local ids = supertable(
      needself and { 'self' },
      params:map(function(param) return param.id end),
      varargs and { '...' }
    ):join(',')

    local prebody = params
      :filter(function(param) return param.prebody end)
      :map(function(param) return param.prebody end)
      :join(' ')

    return ('function(%s) %s %s end'):format(ids, prebody, body)
  end,

  FunctionCall = concat(),
}

local LogicFlow = {
  If = template('if %1 then %2'),
  ElseIf = template('elseif %1 then %2'),
  Else = template('else %1'),
  IfElse = function(...)
    return supertable({ ... }, { 'end' }):join(' ')
  end,

  Return = concat(' '),
}

local Expressions = {
  AtomExpr = echo,
  MoleculeExpr = echo,
  OrganismExpr = echo,
  Expr = concat(),
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
  Core
)

local function isnode(node)
  return type(node) == 'table' and type(node.rule) == 'string'
end

local function compile(node)
  if not isnode(node) then
    return subnode
  elseif type(compiler[node.rule]) == 'function' then
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
