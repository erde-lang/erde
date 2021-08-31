local inspect = require('inspect')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local state = {
  tmpcounter = 0,
}

local function newtmpname()
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

local function indexchain(bodycompiler)
  return function(base, chain, ...)
    local chainexpr = supertable({ base }, chain:map(function(index)
      return index.suffix
    end)):join()

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

local function compiledestructure(islocal, destructure, expr)
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
-- Rule Sets
-- -----------------------------------------------------------------------------

local Core = {
  Name = echo,
  Self = template('self'),
  SelfProperty = template('self.%1'),

  IdBase = concat(),
  Id = echo,
  IdExpr = indexchain(template('return %1')),

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

    local eqstr = ('='):rep(eqstats.max + 1)

    return ('[%s[%s]%s]'):format(
      eqstr,
      values:map(function(v)
        return v.interpolation
          and (']%s]..tostring(%s)..[%s['):format(eqstr, v.value, eqstr)
          or v
      end):join(),
      eqstr
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
  Index = map('optional', 'suffix'),
  IndexChain = pack,

  Destruct = map('keyed', 'name', 'nested', 'default'),
  Destructure = function(...)
    local keycounter = 1
    return supertable({ ... }):each(function(destruct)
      if destruct.keyed then
        destruct.index = ('.%s'):format(destruct.name)
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
      local tmpname = newtmpname()
      return { name = tmpname, prebody = compiledestructure(true, arg, tmpname) }
    else
      return { name = arg, prebody = false }
    end
  end,
  OptArg = function(arg, expr)
    return {
      name = arg.name,
      prebody = supertable({
        ('if %s == nil then %s = %s end'):format(arg.name, arg.name, expr),
        arg.prebody,
      }):join(' '),
    }
  end,
  VarArgs = function(name)
    return {
      name = name,
      prebody = ('local %s = {...}'):format(name),
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

    local names = supertable(
      needself and { 'self' },
      params:map(function(param) return param.name end),
      varargs and { '...' }
    ):join(',')

    local prebody = params
      :filter(function(param) return param.prebody end)
      :map(function(param) return param.prebody end)
      :join(' ')

    return ('function(%s) %s %s end'):format(names, prebody, body)
  end,

  ReturnList = concat(','),
  Return = concat(' '),

  FunctionCall = concat(),
}

local LogicFlow = {
  If = template('if %1 then %2'),
  ElseIf = template('elseif %1 then %2'),
  Else = template('else %1'),
  IfElse = function(...)
    return supertable({ ... }, { 'end' }):join(' ')
  end,
}

local Expressions = {
  SubExpr = echo,
  Expr = concat(),
}

local Operators = {
  NegateOp = template('not %1'),
  UnaryOp = concat(),

  LogicalAnd = concat('and'),
  LogicalOr = concat('or'),
  Binop = concat(),

  CompareOp = concat(),

  Ternary = function(condition, iftrue, iffalse)
    return ('(function() if %s then return %s %s end)()'):format(
      condition,
      iftrue,
      iffalse and ('else return %s'):format(iffalse) or ''
    )
  end,

  NullCoalesce = function(default, backup)
    local tmpname = newtmpname()
    return ([[(function()
      local %s = %s
      if %s ~= nil then return %s else return %s end
    )()]]):format(tmpname, default, tmpname, tmpname, backup)
  end,

  AssignOp= template('%1 = %1 %2 %3'),
}

local Declaration = {
  NameDeclaration = concat(' '),
  VarArgsDeclaration = function(islocal, name, expr)
    return ('%s%s = { %s }'):format(islocal and 'local ' or '', name, expr)
  end,
  DestructureDeclaration = compiledestructure,
  Assignment = indexchain(template('%1 = %2')),
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
