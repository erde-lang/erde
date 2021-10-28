-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function loadLua(code)
  local runner
  if _VERSION:find('5.1') then
    runner = loadstring(code)
  else
    runner = load(code)
  end

  if runner == nil then
    error('Invalid Lua code: ' .. code)
  end

  return runner
end

-- -----------------------------------------------------------------------------
-- has_subtable
-- -----------------------------------------------------------------------------

local function has_subtable(state, args)
  if type(args[1]) ~= 'table' or type(args[2]) ~= 'table' then
    return false
  end

  for key, value in pairs(args[1]) do
    if type(value) == 'table' then
      if not has_subtable(state, { value, args[2][key] }) then
        return false
      end
    elseif value ~= args[2][key] then
      return false
    end
  end

  return true
end

require('say'):set(
  'assertion.has_subtable.positive',
  '%s \nis not a subtable of\n%s'
)

assert:register(
  'assertion',
  'has_subtable',
  has_subtable,
  'assertion.has_subtable.positive'
)

-- -----------------------------------------------------------------------------
-- erde_eval
-- -----------------------------------------------------------------------------

local function erde_eval(state, args)
  return args[1] == loadLua('return ' .. args[2])()
end

require('say'):set(
  'assertion.erde_eval.positive',
  'Eval error. Expected %s, got %s'
)

assert:register(
  'assertion',
  'erde_eval',
  erde_eval,
  'assertion.erde_eval.positive'
)

-- -----------------------------------------------------------------------------
-- erde_run
-- -----------------------------------------------------------------------------

local function erde_run(state, args)
  return args[1] == loadLua(args[2])()
end

require('say'):set(
  'assertion.erde_run.positive',
  'Run error. Expected %s, got %s'
)

assert:register(
  'assertion',
  'erde_run',
  erde_run,
  'assertion.erde_run.positive'
)
