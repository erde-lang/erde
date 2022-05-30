local erde = require('erde')
local pathSep = package.config:sub(1, 1)

local function erdeSearcher(moduleName)
  modulePath = moduleName:gsub('%.', pathSep)

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
        return erde.run(moduleContents)
      end
    end
  end
end

-- https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders
-- https://www.lua.org/manual/5.3/manual.html#pdf-package.searchers
local searchers = package.loaders or package.searchers

for searcher in ipairs(searchers) do
  if searcher == erdeSearcher then
    return
  end
end

-- Place erde loader directly after preloader to prioritize erde files over lua.
table.insert(searchers, 2, erdeSearcher)
