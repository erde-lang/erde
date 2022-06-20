local _targets = { default = '5.1+', current = '5.1+' }
local targetsMT = { __index = _targets}
local targets = setmetatable({}, targetsMT)

-- IMPORTANT: Keep these targets in sync with the CLI target choices!
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

function targetsMT:__newindex(key, value)
  if key ~= 'current' then
    error('`targets` is read only except for the `current` key. Use `target.current = newLuaTarget` to set a new Lua target.')
  end

  if not VALID_LUA_TARGETS[value] then
    error(table.concat({
      'Invalid Lua target:',
      value,
      '. Lua target must be one of:',
      table.concat(VALID_LUA_TARGETS, ', '),
    }, ' '))
  end

  _targets.current = value
end

return targets
