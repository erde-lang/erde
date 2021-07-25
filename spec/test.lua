package.path = '/home/bsuth/projects/luascript/src/?.lua;' .. package.path

local inspect = require('inspect')
local ls = require('luascript')

local function read_file(path)
  local file = io.open(path, 'r')

  if not file then
    return nil
  end

  local content = file:read('*a')
  file:close()

  return content
end

local ast, env = ls.parse(read_file('./test_input.lua', 'test_input.lua'))

print(inspect(ast))
-- print(inspect(env.errorinfo))
