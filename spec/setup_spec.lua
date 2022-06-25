local busted = require('busted') -- Explicit import required for helper scripts
local say = require('say')
local inspect = require('inspect')
local compile = require('erde.compile')

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

-- -----------------------------------------------------------------------------
-- Globals
-- -----------------------------------------------------------------------------

function runErde(erdeCode)
  local luaCode = compile(erdeCode)
  local runner = (loadstring or load)(luaCode)

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
  local expected = args[1]
  local got = runErde('return ' .. args[2])
  local result = deepCompare(expected, got)

  if not result then
    error(('Eval error.\n\n%s\n\n==================================\n\n%s'):format(
      inspect(expected),
      inspect(got)
    ))
  end

  return result
end

say:set('assertion.eval.positive', 'Eval error. Expected %s, got %s')
busted.assert:register('assertion', 'eval', eval, 'assertion.eval.positive')

--
-- run
--

local function run(state, args)
  local expected = args[1]
  local got = runErde(args[2])
  local result = deepCompare(expected, got)

  if not result then
    error(('Run error.\n\n%s\n\n==================================\n\n%s'):format(
      inspect(expected),
      inspect(got)
    ))
  end

  return result
end

say:set('assertion.run.positive', 'Run error. Expected %s, got %s')
busted.assert:register('assertion', 'run', run, 'assertion.run.positive')
