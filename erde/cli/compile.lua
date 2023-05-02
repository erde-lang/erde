local C = require('erde.constants')
local compile = require('erde.compile')

local utils = require('erde.utils')
local file_exists, read_file = utils.file_exists, utils.read_file

local cli_utils = require('erde.cli.utils')
local is_compiled_file, traverse = cli_utils.is_compiled_file, cli_utils.traverse

local function compile_file(path, cli)
  local compile_path = path:gsub('%.erde$', '.lua')
  if cli.outdir then compile_path = cli.outdir .. '/' .. compile_path end

  if not cli.print_compiled and not cli.force then
    if file_exists(compile_path) and not is_compiled_file(compile_path) then
      print(path .. ' => ERROR')
      print('Cannot write to ' .. compile_path .. ': file already exists')
      return false
    end
  end

  local ok, result = pcall(function()
    return compile(read_file(path), { alias = path })
  end)

  if not ok then
    print(path .. ' => ERROR')

    if type(result == 'table') and result.line then
      print(('erde:%d: %s'):format(result.line, result.message))
    else
      print('erde: ' .. tostring(result))
    end

    return false
  end

  if cli.print_compiled then
    print(path)
    print(('-'):rep(#path))
    print(result)
  else
    local dest_file = io.open(compile_path, 'w')
    dest_file:write(result)
    dest_file:close()

    if cli.watch then
      print(('[%s] %s => %s'):format(os.date('%X'), path, compile_path))
    else
      print(('%s => %s'):format(path, compile_path))
    end
  end

  return true
end

local function watch_files(cli)
  local modifications = {}
  local poll_interval = 1 -- seconds

  local has_socket, socket = pcall(function() return require('socket') end)
  local has_posix, posix = pcall(function() return require('posix.unistd') end)
  if not has_socket and not has_posix then
    print(table.concat({
      'WARNING: No libraries with sleep functionality found. This may ',
      'cause high CPU usage while watching. To fix this, you can install ',
      'either LuaSocket (https://luarocks.org/modules/luasocket/luasocket) ',
      'or luaposix (https://luarocks.org/modules/gvvaughan/luaposix)\n',
    }))
  end

  while true do
    traverse(cli, '%.erde$', function(path, attributes)
      if not modifications[path] or modifications[path] ~= attributes.modification then
        modifications[path] = attributes.modification
        compile_file(path, cli)
      end
    end)

    if has_socket then
      socket.sleep(poll_interval)
    elseif has_posix then
      posix.sleep(poll_interval)
    else
      local last_timeout = os.time()
      repeat until os.time() - last_timeout > poll_interval
    end
  end
end

return function(cli)
  if #cli == 0 then
    table.insert(cli, '.')
  end

  if cli.watch then
    -- Use pcall to catch SIGINT
    pcall(function() watch_files(cli) end)
  else
    traverse(cli, '%.erde$', function(path)
      if not compile_file(path, cli) then
        os.exit(1)
      end
    end)
  end
end
