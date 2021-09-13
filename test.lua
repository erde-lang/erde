package.path = './src/?.lua;' .. package.path
package.path = './src/?/init.lua;' .. package.path
package.path = '/home/bsuth/repos/?/src/init.lua;' .. package.path
package.path = '/home/mujin/Documents/?/src/init.lua;' .. package.path

local erde = require('erde')
local inspect = require('inspect')

local function read_file(path)
  local file = io.open(path, 'r')

  if not file then
    return nil
  end

  local content = file:read('*a')
  file:close()

  return content
end

local function write_file(path, content)
  local file = io.open(path, 'w')
  file:write(content)
  file:close()
end

local input = read_file('./examples/operators.erde')
local ast, state = erde.parse(input)
print('STATE: ', inspect(state))
-- print('AST: ', inspect(ast))
print('LUA: ', erde.compile(ast))
