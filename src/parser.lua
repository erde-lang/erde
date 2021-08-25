local inspect = require('inspect')
local lpeg = require('lpeg')
lpeg.locale(lpeg)

local compiler = require('compiler')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- Environment
--
-- Sets the fenv so that we don't have to prefix everything with `lpeg.` and
-- don't have to manually destructure everything.
-- -----------------------------------------------------------------------------

local env = setmetatable({}, { __index = _G })

for k, v in pairs(lpeg) do
  if _G[k] == nil then
    env[k] = v
  end
end

setfenv(1, env)

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local state = {}

function state.reset()
  state.line = 1
  state.colstart = 0
end

function state.newline(position)
  state.colstart = position
  state.line = state.line + 1
end

-- -----------------------------------------------------------------------------
-- Grammar Helpers
-- -----------------------------------------------------------------------------

local function Pad(pattern)
  return V('Space') * pattern * V('Space')
end

local function PadC(pattern)
  return V('Space') * C(pattern) * V('Space')
end

local function List(pattern, separator, options)
  options = options or {}
  min = options.min or 0
  trailing = options.trailing == false and P(true) or separator
  return pattern * (separator * pattern) ^ min * trailing ^ -1
end

local function Sum(...)
  return supertable({ ... }):reduce(function(sum, pattern)
    return sum + pattern
  end, P(false))
end

local function Product(...)
  return supertable({ ... }):reduce(function(product, pattern)
    return product * pattern
  end, P(true))
end

local function Demand(pattern)
  return pattern + Cc('__ORBIT_ERROR__') * Cp() / function(capture, position)
    if capture == '__ORBIT_ERROR__' then
      error(('Line %s, Column %s: Error'):format(
        state.line,
        position - state.colstart
      ))
    else
      return capture
    end
  end
end

-- -----------------------------------------------------------------------------
-- Rule Helpers
-- -----------------------------------------------------------------------------

function Binop(op)
  return V('AtomExpr') * Pad(op) * V('Expr')
end

-- -----------------------------------------------------------------------------
-- Rule Sets
-- -----------------------------------------------------------------------------

function RuleSet(patterns)
  return supertable(patterns):map(function(pattern, rule)
    return Cp() * pattern / function(position, ...)
      local node = supertable(
        { rule = rule, position = position },
        supertable({ ... }):filter(function(value)
          return value ~= nil
        end)
      )
      return #node > 0 and node or nil
    end
  end)
end

local Core = RuleSet({
  Keyword = Pad(Sum(
    P('local'),
    P('if'),
    P('elseif'),
    P('else'),
    P('false'),
    P('true'),
    P('nil'),
    P('return')
  )),

  Id = C(-V('Keyword') * (alpha + P('_')) * (alnum + P('_')) ^ 0),

  Newline = P('\n') * (Cp() / state.newline),
  Space = (V('Newline') + space) ^ 0,

  SingleLineComment = Pad('//') * (P(1) - V('Newline')) ^ 0,
  MultiLineComment = Pad('/*') * (P(1) - P('*/')) ^ 0 * Pad('*/'),
  Comment = V('SingleLineComment') + V('MultiLineComment'),
})

local Numbers = RuleSet({
  Integer = digit ^ 1,
  Exponent = S('eE') * S('+-') ^ -1 * V('Integer'),
  Number = C(Sum(
    Sum( -- float
      digit ^ 0 * P('.') * V('Integer') * V('Exponent') ^ -1,
      V('Integer') * V('Exponent')
    ),
    (P('0x') + P('0X')) * xdigit ^ 1, -- hex
    V('Integer')
  )),
})

local Strings = RuleSet({
  EscapedChar = C(V('Newline') + P('\\') * P(1)),

  Interpolation = P('{') * Pad(C(Demand(V('Expr')))) * P('}'),
  LongString = Product(
    '`',
    (V('EscapedChar') + V('Interpolation') + C(P(1) - P('`'))) ^ 0,
    '`'
  ),

  String = Sum(
    V('LongString'),
    P("'") * (V('EscapedChar') + (P(1) - P("'"))) ^ 0 * P("'"), -- single quote
    P('"') * (V('EscapedChar') + (P(1) - P('"'))) ^ 0 * P('"') -- double quote
  ) / function(s)
    return s
    -- return s
    --   :gsub('\\a', '\a')
    --   :gsub('\\b', '\b')
    --   :gsub('\\f', '\f')
    --   :gsub('\\n', '\n')
    --   :gsub('\\r', '\r')
    --   :gsub('\\t', '\t')
    --   :gsub('\\v', '\v')
    --   :gsub('\\\\', '\\')
    --   :gsub('\\"', '"')
    --   :gsub("\\'", "'")
    --   :gsub('\\[', '[')
    --   :gsub('\\]', ']')
  end,
})

local Tables = RuleSet({
  StringTableKey = V('String'),
  MapTableField = (V('StringTableKey') + V('Id')) * Pad(':') * V('Expr'),
  InlineTableField = Pad(P(':') * V('Id')),

  TableField = V('InlineTableField') + V('MapTableField') + V('Expr'),
  TableFieldList = List(V('TableField'), PadC(',')) + PadC(''),
  Table = PadC('{') * V('TableFieldList') * PadC('}'),

  DotIndex = V('Space') * C('.') * V('Id'),
  BracketIndex = PadC('[') * V('Expr') * PadC(']'),
  ChainIndex = (V('DotIndex') + V('BracketIndex')) ^ 1,
  IndexExpr = (PadC('(') * V('Expr') * PadC(')') + V('Id')) * V('ChainIndex'),

  ArrayDestructure = Pad('[') * List(V('Id'), Pad(',')) * Pad(']'),
  MapDestructure = Pad('{') * List(P(':') * V('Id'), Pad(',')) * Pad('}'),
})

local Functions = RuleSet({
  Arg = V('Id'),
  OptArg = V('Id') * Pad('=') * V('Expr'),
  VarArgs = Pad('...') * V('Id') ^ 0,

  ArrayArg = V('ArrayDestructure'),
  MapArg = V('MapDestructure'),

  ArgList = List(V('Arg') - V('OptArg'), Pad(',')),
  OptArgList = List(V('OptArg'), Pad(',')),
  Params = Sum(
    Product(
      Pad('('),
      Sum(
        Product(
          V('ArgList'),
          (Pad(',') * V('OptArgList')) ^ -1,
          (Pad(',') * V('VarArgs')) ^ -1
        ),
        V('OptArgList') * (Pad(',') * V('VarArgs')) ^ -1,
        V('VarArgs') ^ -1
      ),
      Pad(',') ^ -1,
      Pad(')')
    ),
    V('ArrayDestructure'),
    V('MapDestructure'),
    V('Arg')
  ),

  FunctionBody = V('Expr') + (Pad('{') * V('Block') * Pad('}')),
  SkinnyFunction = V('Params') * Pad('->') * V('FunctionBody'),
  FatFunction = V('Params') * Pad('=>') * V('FunctionBody'),
  Function = V('SkinnyFunction') + V('FatFunction'),

  FunctionCallArgList = (List(V('Id'), Pad(',')) * Pad(',') ^ -1) ^ -1,
  FunctionCallParams = PadC('(') * V('FunctionCallArgList') * PadC(')'),

  FunctionCallBase = PadC('(') * V('Expr') * PadC(')') + V('Id'),
  ExprCall = V('FunctionCallBase') * V('FunctionCallParams'),
  SkinnyFunctionCall = V('IndexExpr') * V('FunctionCallParams'),
  FatFunctionCall = V('FunctionCallBase') * PadC(':') * V('Id') * V('FunctionCallParams'),
  FunctionCall = Sum(
    V('FatFunctionCall'),
    V('SkinnyFunctionCall'),
    V('ExprCall')
  ),
})

local LogicFlow = RuleSet({
  If = Pad('if') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  ElseIf = Pad('elseif') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  Else = Pad('else') * Pad('{') * V('Block') * Pad('}'),
  IfElse = V('If') * V('ElseIf') ^ 0 * V('Else') ^ -1,

  Return = PadC('return') * V('Expr') ^ -1,
})

local Expressions = RuleSet({
  AtomExpr = Sum(
    V('Function'),
    V('Table'),
    V('Id'),
    V('String'),
    V('Number'),
    PadC('true'),
    PadC('false')
  ),

  MoleculeExpr = Sum(
    V('FunctionCall'),
    V('IndexExpr'),
    V('Binop'),
    V('AtomExpr')
  ),

  OrganismExpr = Sum(
    V('Ternary'),
    V('NullCoalescence'),
    V('MoleculeExpr')
  ),

  Expr = V('OrganismExpr') + PadC('(') * V('Expr') * PadC(')'),
})

local Operators = RuleSet({
  LogicalAnd = Binop('&&'),
  LogicalOr = Binop('||'),

  Addition = Binop('+'),
  Subtraction = Binop('-'),
  Multiplication = Binop('*'),
  Division = Binop('/'),
  Modulo = Binop('%'),

  Greater = Binop('>'),
  Less = Binop('<'),
  GreaterEq = Binop('>='),
  LessEq = Binop('<='),
  Eq = Binop('=='),

  Binop = Sum(
    V('LogicalAnd'),
    V('LogicalOr'),
    V('Addition'),
    V('Subtraction'),
    V('Multiplication'),
    V('Division'),
    V('Modulo'),
    V('Greater'),
    V('Less'),
    V('GreaterEq'),
    V('LessEq'),
    V('Eq')
  ),

  Ternary = V('MoleculeExpr') * Pad('?') * V('Expr') * (Pad(':') * V('Expr')) ^ -1,
  NullCoalescence = V('MoleculeExpr') * Pad('??') * V('Expr'),
})

local Declaration = RuleSet({
  IdDeclaration = Product(
    PadC('local') ^ -1,
    V('Id'),
    (PadC('=') * Demand(V('Expr'))) ^ -1
  ),

  ArrayDestructureDeclaration = Product(
    PadC('local') + C(false),
    V('ArrayDestructure'),
    Pad('='),
    Demand(V('Expr'))
  ),

  MapDestructureDeclaration = Product(
    PadC('local') + C(false),
    V('MapDestructure'),
    Pad('='),
    Demand(V('Expr'))
  ),

  Declaration = Sum(
    V('MapDestructureDeclaration'),
    V('ArrayDestructureDeclaration'),
    V('IdDeclaration')
  ),
})

local Blocks = RuleSet({
  Block = V('Statement') ^ 0,
  Statement = Pad(Sum(
    V('FunctionCall'),
    V('Declaration'),
    V('Return'),
    V('IfElse'),
    V('Comment')
  )),
})

-- -----------------------------------------------------------------------------
-- Grammar
-- -----------------------------------------------------------------------------

local grammar = P(supertable(
  { V('Block') },
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
))

return function(subject)
  lpeg.setmaxstack(1000)
  state.reset()
  local ast = grammar:match(subject, nil, {})
  return ast or {}, state
end
