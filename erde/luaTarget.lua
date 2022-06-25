local _luaTarget = { default = '5.1+', current = '5.1+' }
local luaTargetMT = { __index = _luaTarget}
local luaTarget = setmetatable({}, luaTargetMT)

luaTarget.VALID_LUA_TARGETS = {
  'JIT',
  '5.1',
  '5.1+',
  '5.2',
  '5.2+',
  '5.3',
  '5.3+',
  '5.4',
  '5.4+',
}

for i, target in ipairs(luaTarget.VALID_LUA_TARGETS) do
  luaTarget.VALID_LUA_TARGETS[target] = true
end

-- Compiling bit operations for these targets are dangerous, since Mike Pall's
-- LuaBitOp only works on 5.1 + 5.2, bit32 only works on 5.2, and 5.3 + 5.4 have
-- built-in bit operator support.
--
-- In the future, we may want to only disallow bit operators for these targets
-- if the flag in the CLI is not set, but for now we choose to treat them as
-- "invalid" targets to avoid runtime errors.
luaTarget.INVALID_BITOP_LUA_TARGETS = {
  ['5.1+'] = true,
  ['5.2+'] = true,
}

function luaTargetMT:__newindex(key, value)
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

  _luaTarget.current = value
end

return luaTarget
