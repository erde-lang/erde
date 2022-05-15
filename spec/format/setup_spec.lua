local busted = require('busted') -- Explicit import required for helper scripts
local say = require('say')
local inspect = require('inspect')
local format = require('erde.format')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

-- trim6 from http://lua-users.org/wiki/StringTrim
local function trim(s)
  return s:match('^()%s*$') and '' or s:match('^%s*(.*%S)')
end

-- -----------------------------------------------------------------------------
-- Asserts
-- -----------------------------------------------------------------------------

--
-- formatted
-- NOTE: Cannot use assert.format, as it's already used internally by busted.
--

local function formatted(state, args)
  local expected = trim(args[2])
  local got = trim(format(args[1]))
  local result = expected == got

  if not result then
    error(('Format error.\n\n%s\n\n==================================\n\n%s'):format(
      inspect(expected),
      inspect(got)
    ))
  end

  return result
end

say:set('assertion.formatted.positive', 'Format error. Expected %s, got %s')
busted.assert:register(
  'assertion',
  'formatted',
  formatted,
  'assertion.formatted.positive'
)
