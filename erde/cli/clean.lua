local cli_utils = require('erde.cli.utils')
local is_compiled_file, traverse = cli_utils.is_compiled_file, cli_utils.traverse

return function(cli)
  if #cli == 0 then
    table.insert(cli, '.')
  end

  traverse(cli, '%.lua$', function(path)
    if is_compiled_file(path) then
      os.remove(path)
      print(path .. ' => DELETED')
    end
  end)
end
