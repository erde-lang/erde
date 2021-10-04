package.path = './?/init.lua;' .. package.path
package.cpath = './build/?.so;' .. package.cpath
local loadstart = os.clock()

local erde = require('erde')
local erdec = require('erdec')
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
  print(label, ' => ', os.clock() - start)
  print(callback())
end

-- local input = read_file('./examples/scratchpad.erde')
local input = read_file('./examples/benchmark.erde')
print('LOAD => ', os.clock() - loadstart)
benchmark('LUA', function()
  return erde.compile(input)
end, true)
-- benchmark('C', function()
--   return erdec.compile(input)
-- end, true)
