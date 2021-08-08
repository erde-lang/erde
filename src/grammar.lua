local inspect = require('inspect')
local lpeg = require('lpeg')
lpeg.locale(lpeg)

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

function state.Reset()
  state.line = 0
  state.column = 0
end

function state.Newline()
  state.line = state.line + 1
end

-- -----------------------------------------------------------------------------
-- Helpers
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

function Reduce(patterns, fn, value)
  local result = value or P(false)

  for i, pattern in ipairs(patterns) do
    result = fn(pattern, value)
  end

  return result
end

function Sum(patterns)
  return Reduce(patterns, function(pattern, sum)
    return sum + pattern
  end, P(false))
end

function Flag(pattern)
  return C(pattern) / function(capture)
    return capture:len() > 0
  end
end

function Mark(pattern)
  local position = Cg(Cp(), 'position')
  local value = Cg(pattern, 'capture')
  return Ct(position * value)
end

-- -----------------------------------------------------------------------------
-- Grammar
-- -----------------------------------------------------------------------------

local grammar = P({
  V('Lua'),
  Lua = V('Block'),

  Block = V('Statement') ^ 0 / function(...)
    local compiled = ''

    for i, v in ipairs({ ... }) do
      if v.compiled then
        compiled = compiled .. ' ' .. v.compiled
      end
    end

    return { compiled = compiled }
  end,

  Statement = Pad(Sum({
    V('Declaration'),
  })),

  Space = (S('\n') / state.Newline + space) ^ 0,

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

  Id = Mark(-V('Keyword') * (alpha + P('_')) * (alnum + P('_') ^ 0)),
  Expr = Mark(V('Number')),

  Declaration = Flag(Pad('local') ^ -1) * V('Id') * (Pad('=') * V('Expr')) ^ -1 / function(isLocal, id, expr)
    if isLocal then
      return { compiled = ([[local %s = %s]]):format(id.capture, expr.capture) }
    else
      return { compiled = ([[%s = %s]]):format(id.capture, expr.capture) }
    end
  end,

  Literal = Sum({
    Pad('true'),
    Pad('false'),
    V('Number'),
    V('String'),
  }),

  --
  -- Number
  --

  Exponent = S('eE') * S('+-') ^ -1 * digit ^ 1,
  Decimal = (digit ^ 0 + P(true)) * P('.') * digit ^ 1,
  Hex = (P('0x') + P('0X')) * xdigit ^ 1,
  Float = Sum({
    V('Decimal') * V('Exponent') ^ -1,
    digit ^ 1 * V('Exponent'),
  }),
  Int = digit ^ 1,
  Number = V('Hex') + V('Float') + V('Int'),

  --
  -- Strings
  --
  -- TODO: LongString magic docs
  -- TODO: rename LongStringId?
  -- TODO: doc / workaraound string escaped char fixing?
  --
  -- http://www.inf.puc-rio.br/~roberto/lpeg
  -- Example: Lua's long strings
  --

  EscapedChar = P('\\') * P(1),

  SingleQuoteString = P("'") * C((V('EscapedChar') + (P(1) - P("'"))) ^ 0) * P("'"),
  DoubleQuoteString = P('"') * C((V('EscapedChar') + (P(1) - P('"'))) ^ 0) * P('"'),
  ShortString = V('SingleQuoteString') + V('DoubleQuoteString'),

  LongStringStart = '[' * Cg(P('=') ^ 0, 'LongStringId') * '[',
  LongStringEnd = ']' * P('=') ^ 0 * ']',
  LongStringIdCheck = Cmt(
    V('LongStringEnd') * Cb('LongStringId'),
    function(s, i, a, b)
      return a == b
    end
  ),
  LongString = V('LongStringStart') * C((P(1) - V('LongStringEnd')) ^ 0) * V('LongStringEnd'),

  String = V('LongString') + (V('ShortString') / function(s)
    return s
      :gsub('\\a', '\a')
      :gsub('\\b', '\b')
      :gsub('\\f', '\f')
      :gsub('\\n', '\n')
      :gsub('\\r', '\r')
      :gsub('\\t', '\t')
      :gsub('\\v', '\v')
      :gsub('\\\\', '\\')
      :gsub('\\"', '"')
      :gsub("\\'", "'")
      :gsub('\\[', '[')
      :gsub('\\]', ']')
  end),
})

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return function(subject)
  lpeg.setmaxstack(1000)

  state.Reset()
  local ast = grammar:match(subject, nil, {})

  return ast, state
end
