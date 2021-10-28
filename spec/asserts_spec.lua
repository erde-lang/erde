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
  if _VERSION:find('5.1') then
    return args[1] == loadstring('return ' .. args[2])()
  else
    return args[1] == load('return ' .. args[2])()
  end
end

require('say'):set(
  'assertion.erde_eval.positive',
  'Compilation error. Expected %s, got %s'
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
  if _VERSION:find('5.1') then
    return args[1] == loadstring('return ' .. args[2])()
  else
    return args[1] == load('return ' .. args[2])()
  end
end

require('say'):set(
  'assertion.erde_run.positive',
  'Compilation error. Expected %s, got %s'
)

assert:register(
  'assertion',
  'erde_run',
  erde_run,
  'assertion.erde_run.positive'
)
