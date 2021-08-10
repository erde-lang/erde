local inspect = require('inspect')
local lpeg = require('lpeg')
lpeg.locale(lpeg)

local compiler = require('compiler')
local _ = require('utils.underscore')

-- -----------------------------------------------------------------------------
-- Environment
--
-- Sets the fenv so that we don't have to prefix everything with `lpeg.` and
-- don't have to manually destructure everything.
-- -----------------------------------------------------------------------------

local env = setmetatable({}, { __index = _G })

for k, v in pairs(lpeg) do
  -- Do not override globals! For examples, lpeg.print exists...
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
  state.line = 0
  state.column = 0
end

function state.newline()
  state.line = state.line + 1
end

-- -----------------------------------------------------------------------------
-- Grammar Helpers
-- -----------------------------------------------------------------------------

function Pad(pattern)
  return V('Space') * pattern * V('Space')
end

function List(pattern, separator)
  separator = separator or Pad(',')
  return pattern * (separator * pattern) ^ 0
end

function Join(patterns, separator)
  separator = separator or Pad(',')

  if #patterns == 0 then
    return P(true)
  end

  local joined = patterns[1]
  for i = 2, #patterns do
    joined = joined * separator * patterns[i]
  end
  return joined
end

function Sum(patterns)
  return _.reduce(patterns, function(sum, pattern)
    return sum + pattern
  end, P(false))
end

function Product(patterns)
  return _.reduce(patterns, function(product, pattern)
    return product * pattern
  end, P(true))
end

function Flag(pattern)
  return C(pattern) / function(capture)
    return #capture > 0
  end
end

function Mark(pattern)
  local position = Cg(Cp(), 'position')
  local value = Cg(pattern, 'capture')
  return Ct(position * value)
end

function Demand(pattern)
  return pattern + Cc('__KALE_ERROR__') / function(capture)
    if capture == '__KALE_ERROR__' then
      error('test')
    else
      return capture
    end
  end
end

-- -----------------------------------------------------------------------------
-- Parse Helpers
-- -----------------------------------------------------------------------------

function Nil()
  return nil
end

function Subgrammar(patterns)
  return _.map(patterns, function(pattern, rule)
    return pattern / function(...)
      local node = _.merge({
        { rule = rule },
        _.filter({ ... }, function(capture)
          return capture ~= nil
        end),
      })
      return #node > 0 and node or nil
    end
  end)
end

-- -----------------------------------------------------------------------------
-- Atoms
-- -----------------------------------------------------------------------------

local atoms = Subgrammar({
  --
  -- Id
  --

  Keyword = Pad(Sum({
    P('local'),
    P('if'),
    P('elseif'),
    P('else'),
    P('false'),
    P('true'),
    P('nil'),
    P('return'),
  })),

  Id = -V('Keyword') * (alpha + P('_')) * (alnum + P('_') ^ 0),

  --
  -- Number
  --

  Integer = digit ^ 1,
  Exponent = S('eE') * S('+-') ^ -1 * V('Integer'),
  Number = Sum({
    Sum({ -- float
      digit ^ 0 * P('.') * V('Integer') * V('Exponent') ^ -1,
      V('Integer') * V('Exponent'),
    }),
    (P('0x') + P('0X')) * xdigit ^ 1, -- hex
    V('Integer'),
  }),

  --
  -- Strings
  --

  EscapedChar = P('\\') * P(1),

  Interpolation = P('{') * Demand(Pad(V('Expr'))) * P('}'),
  LongString = Product({
    '`',
    (V('EscapedChar') + V('Interpolation') + (P(1) - P('`'))) ^ 0,
    '`',
  }),

  String = Sum({
    V('LongString'),
    P("'") * (V('EscapedChar') + (P(1) - P("'"))) ^ 0 * P("'"), -- single quote
    P('"') * (V('EscapedChar') + (P(1) - P('"'))) ^ 0 * P('"'), -- double quote
  }) / function(s)
    print(inspect(s))
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
  -- Misc
  --

  Space = (S('\n') / state.newline + space) ^ 0 / Nil,
})

-- -----------------------------------------------------------------------------
-- Molecules
-- -----------------------------------------------------------------------------

local molecules = Subgrammar({
  Literal = Sum({
    Pad('true'),
    Pad('false'),
    V('Number'),
    V('String'),
  }),

  Expr = Sum({
    V('Number'),
    V('String'),
    V('Id'),
  }),
})

-- -----------------------------------------------------------------------------
-- Organisms
-- -----------------------------------------------------------------------------

local organisms = Subgrammar({
  Declaration = Product({
    Flag(Pad('local') ^ -1),
    Mark(V('Id')),
    Pad('=') * Demand(Mark(V('Expr'))) ^ -1,
  }),
})

-- -----------------------------------------------------------------------------
-- Grammar
-- -----------------------------------------------------------------------------

local grammar = P(_.merge({
  atoms,
  molecules,
  organisms,
  {
    V('Lua'),
    Lua = V('Block'),
    Block = V('Statement') ^ 0,
    Statement = Pad(Sum({
      V('Declaration'),
    })),
  },
}))

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return function(subject)
  lpeg.setmaxstack(1000)

  state.reset()
  local ast = grammar:match(subject, nil, {})

  return ast or {}, state
end
