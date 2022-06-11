local targets = {}

local VALID_LUA_TARGETS = {
  ['JIT'] = true,
  ['5.1'] = true,
  ['5.1+'] = true,
  ['5.2'] = true,
  ['5.2+'] = true,
  ['5.3'] = true,
  ['5.3+'] = true,
  ['5.4'] = true,
  ['5.4+'] = true,
}

function targets:set(...)
  for i, target in ipairs({ ... }) do
    if not VALID_LUA_TARGETS[target] then
      error(table.concat({
        'Invalid Lua target:',
        target,
        'Lua targets must be one of:',
        table.concat(VALID_LUA_TARGETS, ', '),
      }, ' '))
    end
  end

end

return targets
