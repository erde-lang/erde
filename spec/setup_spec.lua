local busted = require('busted') -- Explicit import required for helper scripts
local say = require('say')

-- -----------------------------------------------------------------------------
-- Globals
-- -----------------------------------------------------------------------------

compile = require('erde.compile')
parse = require('erde.parse')

function loadErde(code)
  local runner = loadstring(code)

  if runner == nil then
    error('Invalid Lua code: ' .. code)
  end

  return runner
end

function evalErde(expr)
  return loadErde('return ' .. expr)()
end

function runErde(code)
  return loadErde(code)()
end

function deepCompare(a, b)
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
  return deepCompare(args[1], evalErde(args[2]))
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
