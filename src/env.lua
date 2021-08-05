local lpeg = require('lpeg')
lpeg.locale(lpeg)

-- -----------------------------------------------------------------------------
-- Environment
-- -----------------------------------------------------------------------------

local env = {}
setmetatable(env, { __index = _G })

for k, v in pairs(lpeg) do
  -- Do not override globals! For examples, lpeg.print exists...
  if _G[k] == nil then
    env[k] = v
  end
end

-- -----------------------------------------------------------------------------
-- Extended PatternHelpers
-- -----------------------------------------------------------------------------

--
-- Exact
--

function env.E(pattern, n)
  return (pattern ^ n) ^ -n
end

--
-- Word
--

function env.W(pattern)
  return (lpeg.space ^ 0) * pattern * (lpeg.space ^ 0)
end

--
-- Word Capture
--

function env.Wc(pattern)
  return (lpeg.space ^ 0) * C(pattern) * (lpeg.space ^ 0)
end

-- -----------------------------------------------------------------------------
-- Lists
-- -----------------------------------------------------------------------------

--
-- List
--

function env.L(pattern, separator)
  separator = separator or env.W(',')
  return pattern * (separator * pattern) ^ 0
end

--
-- List Join
--

function env.Lj(patterns, separator)
  separator = separator or env.W(',')

  if #patterns == 0 then
    return lpeg.P(true)
  end

  local joined = patterns[1]
  for i = 2, #patterns do
    joined = joined * separator * patterns[i]
  end
  return joined
end

-- -----------------------------------------------------------------------------
-- Merge
-- -----------------------------------------------------------------------------

--
-- Merge
--

function env.M(patterns, macro, value)
  local result = value or lpeg.P(false)

  for i, pattern in ipairs(patterns) do
    result = macro(pattern, value)
  end

  return result
end

--
-- Merge Sum
--

function env.Ms(patterns)
  return env.M(patterns, function(pattern, sum)
    return sum + pattern
  end, lpeg.P(false))
end

-- -----------------------------------------------------------------------------
-- Tags
-- -----------------------------------------------------------------------------

--
-- Tag
--

function env.T(tag, pattern)
  return lpeg.Ct(
    lpeg.Cg(lpeg.Cp(), 'position') * lpeg.Cg(lpeg.Cc(tag), 'tag') * pattern
  )
end

-- -----------------------------------------------------------------------------
-- Return (Environment Loader)
-- -----------------------------------------------------------------------------

return function()
  setfenv(2, env)
end
