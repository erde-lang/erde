local C = require('erde.constants')

local _luaTarget = { default = '5.1+', current = '5.1+' }
local luaTargetMT = { __index = _luaTarget }
local luaTarget = setmetatable({}, luaTargetMT)

function luaTargetMT:__newindex(key, value)
  if key == 'current' then
    if not C.VALID_LUA_TARGETS[value] then
      error(table.concat({
        'Invalid Lua target:',
        value,
        '. Lua target must be one of:',
        table.concat(C.VALID_LUA_TARGETS, ', '),
      }, ' '))
    end

    _luaTarget.current = value
  end
end

return luaTarget
