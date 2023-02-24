local C = require('erde.constants')
local compile = require('erde.compile')

local utils = require('erde.utils')
local file_exists = utils.file_exists

local cli_utils = require('erde.cli.utils')
local is_compiled_file, traverse = cli_utils.is_compiled_file, cli_utils.traverse

local function compile_file(path, options)
  local compile_path = path:gsub('%.erde$', '.lua')
  if options.outdir then compile_path = options.outdir .. '/' .. compile_path end

  if not options.print_compiled and not options.force then
    if file_exists(compile_path) and not is_compiled_file(compile_path) then
      print(path .. ' => ERROR')
      print('Cannot write to ' .. compile_path .. ': file already exists')
      return false
    end
  end

  local src_file = io.open(path, 'r')
  local src = src_file:read('*a')
  src_file:close()

  local ok, result = pcall(function()
    return compile(src)
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

  if options.print_compiled then
    print(path)
    print(('-'):rep(#path))
    print(result)
  else
    local dest_file = io.open(compile_path, 'w')
    dest_file:write(result)
    dest_file:close()

    if options.show_timestamp then
      print(('[%s] %s => %s'):format(os.date('%X'), path, compile_path))
    else
      print(('%s => %s'):format(path, compile_path))
    end
  end

  return true
end

local function watch_files(paths, compile_options)
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
    traverse(paths, '%.erde$', function(path, attributes)
      if not modifications[path] or modifications[path] ~= attributes.modification then
        modifications[path] = attributes.modification
        compile_file(path, compile_options)
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

  local compile_options = {
    force = cli.force,
    outdir = cli.outdir,
    print_compiled = cli.print_compiled,
    show_timestamp = cli.watch,
  }

  if cli.watch then
    -- Use pcall to catch SIGINT
    pcall(function() watch_files(cli, compile_options) end)
  else
    traverse(cli, '%.erde$', function(path)
      if not compile_file(path, compile_options) then
        os.exit(1)
      end
    end)
  end
end
