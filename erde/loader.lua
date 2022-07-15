local C = require('erde.constants')
local run = require('erde.run')
local luaTarget = require('erde.luaTarget')

-- https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders
-- https://www.lua.org/manual/5.2/manual.html#pdf-package.searchers
local searchers = package.loaders or package.searchers

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

return { load = load, unload = unload }
