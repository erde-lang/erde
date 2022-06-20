-- This module allows loading `.erde` modules directly from Lua scripts by
-- injecting a custom package searcher. This searcher may be removed later if
-- required.
--
-- Usage: Adding the loader (default targets Lua 5.1+)
--    require('erde.loader').load()
--
-- Usage: Adding the loader for a specific target
--    require('erde.loader').load('5.3+')
--
-- Usage: Removing the loader
--    require('erde.loader').unload()
--
-- NOTE: While it is _technically_ possible to dynamically change the Lua target
-- at runtime, doing so may be dangerous. For example, if the user loads an Erde
-- module targeting 5.2, then changes the target to 5.1, the previously loaded
-- Erde module will NOT be rerun and may potentially contain 5.1 incompatible
-- code. It is the job of the developer to ensure that such a situation does not
-- arise or to reload modules appropriately. We do not do any reloading on our
-- side, as loading a module may contain side effects.
--
-- LINKS:
-- https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders
-- https://www.lua.org/manual/5.2/manual.html#pdf-package.searchers

local C = require('erde.constants')
local erde = require('erde')
local targets = require('erde.targets')

local searchers = package.loaders or package.searchers

local function erdeSearcher(moduleName)
  modulePath = moduleName:gsub('%.', C.PATH_SEPARATOR)

  for path in package.path:gmatch('[^;]+') do
    local fullModulePath = path:gsub('%.lua', '.erde'):gsub('?', modulePath)
    local moduleFile = io.open(fullModulePath)

    if moduleFile ~= nil then
      moduleFile:close()

      return function()
        local moduleFile = io.open(fullModulePath)

        if moduleFile == nil then
          return 'File no longer exists: ' .. fullModulePath
        end

        local moduleContents = moduleFile:read('*a')
        moduleFile:close()
        return erde.run(moduleContents, targets.current)
      end
    end
  end
end

local function load(newLuaTarget)
  if newLuaTarget ~= nil then
    targets.current = newLuaTarget
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
