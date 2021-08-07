local lpeg = require('lpeg')
lpeg.locale(lpeg)

-- -----------------------------------------------------------------------------
-- Environment
-- -----------------------------------------------------------------------------

local env = {
  W = function(pattern) -- Word
    return (lpeg.space ^ 0) * pattern * (lpeg.space ^ 0)
  end,

  Wc = function(pattern) -- Word Capture
    return (lpeg.space ^ 0) * C(pattern) * (lpeg.space ^ 0)
  end,

  L = function(pattern, separator) -- List
    separator = separator or env.W(',')
    return pattern * (separator * pattern) ^ 0
  end,

  Lj = function(patterns, separator) -- List Join
    separator = separator or env.W(',')

    if #patterns == 0 then
      return lpeg.P(true)
    end

    local joined = patterns[1]
    for i = 2, #patterns do
      joined = joined * separator * patterns[i]
    end
    return joined
  end,

  M = function(patterns, macro, value) -- Merge
    local result = value or lpeg.P(false)

    for i, pattern in ipairs(patterns) do
      result = macro(pattern, value)
    end

    return result
  end,

  Ms = function(patterns) -- Merge Sum
    return env.M(patterns, function(pattern, sum)
      return sum + pattern
    end, lpeg.P(false))
  end,

  T = function(tag, pattern) -- Tag
    return lpeg.Ct(
      lpeg.Cg(lpeg.Cp(), 'position') * lpeg.Cg(lpeg.Cc(tag), 'tag') * pattern
    )
  end,
}

for k, v in pairs(lpeg) do
  -- Do not override globals! For examples, lpeg.print exists...
  if env[k] == nil and _G[k] == nil then
    env[k] = v
  end
end

setfenv(1, setmetatable(env, { __index = _G }))

-- -----------------------------------------------------------------------------
-- Grammar
-- -----------------------------------------------------------------------------

return P({
  V('Lua'),
  Lua = V('Number'),

  Keyword = Ms({
    W('local'),
    W('const'),
    W('if'),
    W('elseif'),
    W('else'),
    W('false'),
    W('true'),
    W('nil'),
    W('in'),
    W('return'),
  }),

  Identifier = -V('Keyword') * C((alpha + P('_')) * (alnum + P('_') ^ 0)),
  Declaration = (W('local') + W('const')) * V('Identifier') * (W('=') * V('Expression')) ^ -1,

  Literal = Ms({
    W('true'),
    W('false'),
    V('Number'),
    V('String'),
  }),

  Expression = '',

  --
  -- Number
  --

  Exponent = S('eE') * S('+-') ^ -1 * digit ^ 1,
  Decimal = (digit ^ 0 + P(true)) * P('.') * digit ^ 1,

  Hex = (P('0x') + P('0X')) * xdigit ^ 1,
  Float = Ms({
    V('Decimal') * V('Exponent') ^ -1,
    digit ^ 1 * V('Exponent'),
  }),
  Int = digit ^ 1,

  Number = T('Number', Cg(V('Hex') + V('Float') + V('Int'), 'value')),
})
