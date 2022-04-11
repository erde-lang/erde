local busted = require('busted') -- Explicit import required for helper scripts
local say = require('say')
local compile = require('erde.compile')
local format = require('erde.format')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function deepCompare(a, b)
  if type(a) ~= 'table' or type(b) ~= 'table' then
    return a == b
  end

  for key in pairs(a) do
    if not deepCompare(a[key], b[key]) then
      return false
    end
  end

  return true
end

-- trim6 from http://lua-users.org/wiki/StringTrim
local function trim(s)
  return s:match('^()%s*$') and '' or s:match('^%s*(.*%S)')
end

-- -----------------------------------------------------------------------------
-- Globals
-- -----------------------------------------------------------------------------

function runErde(erdeCode)
  local luaCode = compile(erdeCode)
  local runner = loadstring(luaCode)

  if runner == nil then
    error('Invalid Lua code: ' .. luaCode)
  end

  return runner()
end

-- -----------------------------------------------------------------------------
-- Asserts
-- -----------------------------------------------------------------------------

--
-- subtable
--

local function subtable(state, args)
  if type(args[1]) ~= 'table' or type(args[2]) ~= 'table' then
    return false
  end

  for key, value in pairs(args[1]) do
    if type(value) == 'table' then
      if not subtable(state, { value, args[2][key] }) then
        return false
      end
    elseif value ~= args[2][key] then
      return false
    end
  end

  return true
end

say:set('assertion.subtable.positive', '%s \nis not a subtable of\n%s')

busted.assert:register(
  'assertion',
  'subtable',
  subtable,
  'assertion.subtable.positive'
)

--
-- eval
--

local function eval(state, args)
  return deepCompare(args[1], runErde('return ' .. args[2]))
end

say:set('assertion.eval.positive', 'Eval error. Expected %s, got %s')
busted.assert:register('assertion', 'eval', eval, 'assertion.eval.positive')

--
-- run
--

local function run(state, args)
  return deepCompare(args[1], runErde(args[2]))
end

say:set('assertion.run.positive', 'Run error. Expected %s, got %s')
busted.assert:register('assertion', 'run', run, 'assertion.run.positive')

--
-- format
--

local function formatted(state, args)
  return trim(args[1]) == trim(format(args[2]))
end

say:set('assertion.formatted.positive', 'Format error. Expected %s, got %s')
busted.assert:register(
  'assertion',
  'formatted',
  formatted,
  'assertion.formatted.positive'
)
