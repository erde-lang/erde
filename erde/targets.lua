-- This module contains various utility functions / constants relating to Lua
-- target (i.e. the Lua versions that compiled code is assumed to run on). It
-- is meant for internal use only.

local _targets = { default = '5.1+', current = '5.1+' }
local targetsMT = { __index = _targets}
local targets = setmetatable({}, targetsMT)

-- The valid Lua targets. JIT is provided as a separate option as it assumes
-- the Lua 5.1 language spec (i.e. number syntax is limited to Lua 5.1) but has
-- extensions such as the support for `goto` statements.
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

-- The __newindex metamethod here makes everything but the `current` key of 
-- `targets` read only. Additionally, when `target.current` is being set we 
-- validate the new Lua target to ensure it's valid.
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
