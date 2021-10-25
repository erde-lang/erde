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
-- erde_compile_expr
-- -----------------------------------------------------------------------------

local function erde_compile_expr(state, args)
  return args[1] == loadstring('return ' .. args[2])()
end

require('say'):set(
  'assertion.erde_compile_expr.positive',
  'Compilation error. Expected %s, got %s'
)

assert:register(
  'assertion',
  'erde_compile_expr',
  erde_compile_expr,
  'assertion.erde_compile_expr.positive'
)
