local inspect = require('inspect')
local lpeg = require('lpeg')
lpeg.locale(lpeg)

local compiler = require('compiler')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- Notes
--
-- NOTE1: C(P(true)) is used in this rule to ensure this rule actually captures
-- something, otherwise it will not be placed in the AST.
-- -----------------------------------------------------------------------------

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

function Pad(pattern)
  return V('Space') * pattern * V('Space')
end

function List(pattern, separator, threshold)
  threshold = threshold or 0
  return pattern * (separator * pattern) ^ threshold
end

function Sum(...)
  return supertable({ ... }):reduce(function(sum, pattern)
    return sum + pattern
  end, P(false))
end

function Product(...)
  return supertable({ ... }):reduce(function(product, pattern)
    return product * pattern
  end, P(true))
end

function Demand(pattern)
  return pattern + Cc('__KALE_ERROR__') * Cp() / function(capture, position)
    if capture == '__KALE_ERROR__' then
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
-- Parse Helpers
-- -----------------------------------------------------------------------------

function Subgrammar(patterns)
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

-- -----------------------------------------------------------------------------
-- Atoms
-- -----------------------------------------------------------------------------

local atoms = Subgrammar({
  --
  -- Core
  --

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
  Space = (P('\n') * (Cp() / state.newline) + space) ^ 0,

  --
  -- Number
  --

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

  --
  -- Strings
  --

  EscapedChar = C(P('\\') * P(1)),

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
  
  --
  -- Table
  --

  TableStringField = V('String'),
  TableField = (V('TableStringField') + V('Id')) * Pad(':') * V('Expr'),
  Table = Product(
    Pad('{'),
    List(V('TableField') + V('Expr'), Pad(',')),
    Pad(',') ^ -1,
    Pad('}')
  ),

  --
  -- Functions
  --

  Arg = V('Id'),
  OptArg = V('Id') * Pad('=') * V('Expr'),
  VarArgs = Pad('...') * V('Id') ^ 0,

  ArgList = List(V('Arg') - V('OptArg'), Pad(',')),
  OptArgList = List(V('OptArg'), Pad(',')),
  Parameters = Product(
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

  FunctionBody = V('Expr') + (Pad('{') * V('Block') * Pad('}')),
  SkinnyFunction = V('Parameters') * Pad('->') * V('FunctionBody'),
  FatFunction = V('Parameters') * Pad('=>') * V('FunctionBody'),
  Function = V('SkinnyFunction') + V('FatFunction'),
})

-- -----------------------------------------------------------------------------
-- Molecules
-- -----------------------------------------------------------------------------

local molecules = Subgrammar({
  --
  -- Logic Flow
  --

  If = Pad('if') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  ElseIf = Pad('elseif') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  Else = Pad('else') * Pad('{') * V('Block') * Pad('}'),
  IfElse = V('If') * V('ElseIf') ^ 0 * V('Else') ^ -1,

  Return = Pad('return') * V('Expr') ^ -1 * C(P(true)), -- NOTE1

  --
  -- Expressions
  --

  NumberExpr = V('Number') + V('Id'),
  StringExpr = V('String') + V('Id'),

  LiteralExpr = Sum(
    Pad(C('true')),
    Pad(C('false')),
    V('Number'),
    V('String')
  ),


  Expr = Sum(
    -- V('Ternary'),
    -- V('NullCoalescence'),
    V('Addition'),
    V('Function'),
    V('Table'),
    V('LiteralExpr'),
    V('Id')
  ),

  --
  -- Operators
  --

  
  -- And = V('Expr') * Pad('&&') * V('Expr'),
  -- Or = V('Expr') * Pad('||') * V('Expr'),
  AdditionCore = V('NumberExpr') * (Pad('+') * V('Addition')) ^ 1,
  Addition = Sum(
    Pad('(') * V('Addition') * Demand(Pad(')')),
    V('AdditionCore')
  ),
  -- Subtraction = V('Expr') * Pad('-') * V('Expr'),
  -- Multiplication = V('Expr') * Pad('-') * V('Expr'),
  -- Division = V('Expr') * Pad('/') * V('Expr'),
  -- Modulo = V('Number') * Pad('%') * V('Number'),
  -- Ternary = V('Condition') * Pad('?') * V('Expr') * (Pad(':') * V('Expr')) ^ -1,
  -- NullCoalescence = V('Condition') * Pad('??') * V('Expr'),
})

-- -----------------------------------------------------------------------------
-- Organisms
-- -----------------------------------------------------------------------------

local organisms = Subgrammar({
  Kale = V('Block'),
  Block = V('Statement') ^ 0,
  Statement = Pad(Sum(
    V('ArrayDestructure'),
    V('MapDestructure'),
    V('Declaration'),
    V('Return'),
    V('IfElse')
  )),

  ArrayDestructure = Product(
    C(Pad('local') ^ -1),
    Pad('['),
    List(V('Id'), Pad(',')),
    Pad(']'),
    Pad('='),
    Demand(V('Expr'))
  ),

  MapDestructure = Product(
    C(Pad('local') ^ -1),
    Pad('{'),
    List(V('Id'), Pad(',')),
    Pad('}'),
    Pad('='),
    Demand(V('Expr'))
  ),

  Declaration = Product(
    C(Pad('local') ^ -1),
    V('Id'),
    (Pad('=') * Demand(V('Expr'))) ^ -1
  ),
})

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

local grammar = P(supertable({ V('Kale') }, atoms, molecules, organisms))

return function(subject)
  lpeg.setmaxstack(1000)
  state.reset()
  local ast = grammar:match(subject, nil, {})
  return ast or {}, state
end
