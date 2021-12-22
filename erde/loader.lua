-- Loader for `*.erde` files. Mutates the global require function.
local erde = require('erde')
local nativeRequire = require
local packagePath = package.path

function require(moduleName)
  for path in packagePath:gmatch('[^;]+') do
    local erdePath = path:gsub('%.lua', '.erde'):gsub('?', moduleName)
    moduleFile = io.open(erdePath)

    if moduleFile ~= nil then
      return erde.run(moduleFile:read('*a'))
    end
  end

  return nativeRequire(moduleName)
end
