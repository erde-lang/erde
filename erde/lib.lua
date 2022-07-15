-- This module contains higher level functions for use either via API or
-- internally (mostly in the CLI).

local C = require('erde.constants')
local compile = require('erde.compile')
local luaTarget = require('erde.luaTarget')

local load = loadstring or load

-- https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders
-- https://www.lua.org/manual/5.2/manual.html#pdf-package.searchers
local searchers = package.loaders or package.searchers

-- -----------------------------------------------------------------------------
-- Debug
-- -----------------------------------------------------------------------------

local function rewrite(err, sourceMap, sourceName)
  errSource, errLine, errMsg = err:match('^(.*):(%d+): (.*)$')
  errLine = tonumber(errLine)

  if sourceMap == nil then
    -- TODO: use sourceMapCache
  end

  return ('%s:%d: %s'):format(
    sourceName or errSource,
    sourceMap ~= nil and sourceMap[errLine] or errLine,
    errMsg
  )
end

local function traceback()
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Run
-- -----------------------------------------------------------------------------

local cachedSourceMaps = {}

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
    error(rewrite(result, sourceMap, sourceName))
  end

  return result
end

local function runString(source, sourceName)
  sourceName = sourceName or '[loaded string]'
  local compiled, sourceMap = compile(source)
  return runCompiled(compiled, sourceMap, sourceName)
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
  -- memory usage?
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

-- -----------------------------------------------------------------------------
-- Loader
-- -----------------------------------------------------------------------------

local function erdeSearcher(moduleName)
  local modulePath = moduleName:gsub('%.', C.PATH_SEPARATOR)

  for path in package.path:gmatch('[^;]+') do
    local fullModulePath = path:gsub('%.lua', '.erde'):gsub('?', modulePath)
    local moduleFile = io.open(fullModulePath)

    if moduleFile ~= nil then
      moduleFile:close()

      return function()
        local _, result = pcall(function()
          return run.file(fullModulePath)
        end)
        return result
      end
    end
  end
end

local function load(newLuaTarget)
  if newLuaTarget ~= nil then
    luaTarget.current = newLuaTarget
  end

  for i, searcher in ipairs(searchers) do
    if searcher == erdeSearcher then
      return
    end
  end

  -- We need to place the searcher before the `.lua` searcher to prioritize Erde
  -- modules over Lua modules. If the user has compiled an Erde project before
  -- but the compiled files are out of date, we need to avoid loading the
  -- outdated modules.
  table.insert(searchers, 2, erdeSearcher)
end

local function unload()
  for i, searcher in ipairs(searchers) do
    if searcher == erdeSearcher then
      table.remove(searchers, i)
      return
    end
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  rewrite = rewrite,
  traceback = traceback,
  runString = runString,
  runFile = runFile,
  luaTarget = luaTarget,
  load = load,
  unload = unload,
}
