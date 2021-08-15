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

function Pad(pattern)
  return V('Space') * pattern * V('Space')
end

function List(pattern, separator)
  return pattern * (separator * pattern) ^ 0
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
  -- Functions
  --

  Arg = V('Id'),
  Args = List(V('Arg') - V('OptArg'), Pad(',')),
  OptArg = V('Id') * Pad('=') * V('Expr'),
  OptArgs = List(V('OptArg'), Pad(',')),
  VarArgs = Pad('...') * V('Id') ^ 0,

  Parameters = Sum(
    Product(
      List(V('Arg') - V('OptArg'), Pad(',')),
      (Pad(',') * List(V('OptArg'), Pad(','))) ^ -1,
      (Pad(',') * V('VarArgs')) ^ -1
    ),
    Product(
      List(V('OptArg'), Pad(',')),
      (Pad(',') * V('VarArgs')) ^ -1
    ),
    V('VarArgs') ^ -1
  ),

  Function = Product(
    Pad('(') * V('Parameters') * Pad(',') ^ -1 * Pad(')'),
    Pad('=>'),
    V('Expr') + (Pad('{') * V('Block') * Pad('}'))
  ),

  --
  -- Logic Flow
  --

  If = Pad('if') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  ElseIf = Pad('elseif') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  Else = Pad('else') * Pad('{') * V('Block') * Pad('}'),
  IfStatement = V('If') * V('ElseIf') ^ 0 * V('Else') ^ -1,
})

-- -----------------------------------------------------------------------------
-- Molecules
-- -----------------------------------------------------------------------------

local molecules = Subgrammar({
  Literal = Sum(Pad(C('true')), Pad(C('false')), V('Number'), V('String')),
  Expr = Sum(V('Function'), V('Literal'), V('Id')),
})

-- -----------------------------------------------------------------------------
-- Organisms
-- -----------------------------------------------------------------------------

local organisms = Subgrammar({
  Kale = V('Block'),
  Block = V('Statement') ^ 0,
  -- Statement = Pad(Sum(V('Declaration'), V('IfStatement'))),
  Statement = Pad(Sum(V('Declaration'), V('IfStatement'))),

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
