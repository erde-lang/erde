local compile = require('erde.compile')
local debug = require('erde.debug')

local cachedSourceMaps = {}
local load = loadstring or load

local function runCompiled(compiled, sourceMap, sourceName)
  local loader, err = load(compiled)

  if type(loader) ~= 'function' then
    error(table.concat({
      'Failed to load compiled Lua.',
      'Error: ' .. err,
      'Compiled Code: ' .. compiled,
    }, '\n'))
  end

  local ok, result = pcall(loader)

  if not ok then
    error(debug.rewrite(result, sourceMap, sourceName))
  end

  return result
end

local function runFile(filePath)
  local file = io.open(filePath)

  if file == nil then
    error('File does not exist: ' .. filePath)
  end

  local source = file:read('*a')
  file:close()

  local compiled, sourceMap = compile(source)

  -- TODO: provide option to disable source map caching, as it may increase
  -- memory usage. This, however, may render the erde.debug functions
  -- inaccurate.
  cachedSourceMaps[filePath] = sourceMap

  local ok, result = pcall(function()
    return runCompiled(compiled, sourceMap)
  end)

  if not ok then
    print('erde: ' .. result)
    os.exit(1)
  end

  return result
end

local function runString(source, sourceName)
  sourceName = sourceName or '[loaded string]'
  local compiled, sourceMap = compile(source)
  return runCompiled(compiled, sourceMap, sourceName)
end

return { file = runFile, string = runString }
