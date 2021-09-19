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

local function benchmark(label, callback, stress)
  local start = os.clock()
  if stress then
    for i = 1, 1000 do callback() end
  end
  print(callback())
  print(label, ' => ', os.clock() - start)
end

-- local input = read_file('./examples/scratchpad.erde')
local input = read_file('./examples/tables.erde')
-- benchmark('PARSE', function()
--   return erde.parse(input)
-- end, false)
benchmark('COMPILE', function()
  return erde.compile(input)
end, false)
-- benchmark('FORMAT', function()
--   return erde.format(input)
-- end, false)
