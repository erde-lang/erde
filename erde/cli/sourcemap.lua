local compile = require('erde.compile')

local utils = require('erde.utils')
local read_file = utils.read_file

local cli_utils = require('erde.cli.utils')
local terminate = cli_utils.terminate

return function(cli)
  local path, line = cli[1], cli[2]

  if path == nil then
    terminate('Missing erde file to map')
  elseif line == nil then
    terminate('Missing line number to map')
  end

  local ok, result, sourcemap = pcall(function()
    return compile(read_file(path), { alias = path })
  end)

  if ok then
    print(('%s => %s'):format(line, sourcemap[tonumber(line)]))
  else
    print('Failed to compile ' .. path)

    if type(result == 'table') and result.line then
      print(('erde:%d: %s'):format(result.line, result.message))
    else
      print('erde: ' .. tostring(result))
    end
  end
end
