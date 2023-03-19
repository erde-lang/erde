local lib = require('erde.lib')

local utils = require('erde.utils')
local read_file = utils.read_file

local cli_utils = require('erde.cli.utils')
local terminate = cli_utils.terminate

-- IMPORTANT: THIS IS AN ERDE SOURCE LOADER AND MUST ADHERE TO THE USAGE SPEC OF
-- `__erde_internal_load_source__`!
return function(cli, script_args)
  lib.load()

  -- Replace Lua's global args with what the script expects as if it were run
  -- from the Lua VM directly.
  arg = script_args

  local ok, result = xpcall(function()
    local source = read_file(cli.script)
    local result = lib.__erde_internal_load_source__(source, cli.script)
    return result
  end, lib.traceback)

  if not ok then
    terminate('erde: ' .. result)
  end
end
