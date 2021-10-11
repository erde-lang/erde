local function has_subtable(state, args)
  local has_key = false

  if not type(args[1]) == 'table' or #args ~= 2 then
    return false
  end

  for key, value in pairs(args[1]) do
    if key == args[2] then
      has_key = true
    end
  end

  return has_key
end

assert:register(
  'assertion',
  'has_subtable',
  has_subtable,
  'Expected %s \nto have property: %s',
  'Expected %s \nto not have property: %s'
)
