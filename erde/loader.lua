local erde = require('erde')
local pathSep = package.config:sub(1, 1)

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

  return 'Failed to find erde module'
end

local loaders = package.loaders or package.searchers

for loader in ipairs(loaders) do
  if loader == erdeLoader then
    return
  end
end

-- Place erde loader first to prioritize erde files over lua ones.
table.insert(loaders, 1, erdeLoader)
