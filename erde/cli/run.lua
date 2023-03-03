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

  local ok, result = pcall(function()
    local source = read_file(cli.script)

    local result = lib.__erde_internal_load_source__(source, cli.script, {
      bitlib = cli.bitlib,
      rewrite_errors = true,
    })

    return result
  end)

  if not ok then
    if type(result) == 'table' and result.__is_erde_error__ then
      terminate('erde: ' .. (result.stacktrace or result.message))
    else
      terminate(table.concat({
        'Internal error: ' .. tostring(result),
        'Please report this at: https://github.com/erde-lang/erde/issues',
      }, '\n'))
    end
  end
end
