local erde = require('erde')
local pathSep = package.config:sub(1, 1)

-- TODO: use package.erdepath? similar to moonscript

local function erdeLoader(moduleName)
  moduleName = moduleName:gsub('%.', pathSep)

  for path in package.path:gmatch('[^;]+') do
    local erdePath = path:gsub('%.lua', '.erde'):gsub('?', moduleName)
    local moduleFile = io.open(erdePath)

    if moduleFile ~= nil then
      return function()
        return erde.run(moduleFile:read('*a'))
      end
    end
  end

  return 'Failed to find module'
end

local loaders = package.loaders or package.searchers

for loader in ipairs(loaders) do
  if loader == erdeLoader then
    return
  end
end

table.insert(loaders, erdeLoader)
