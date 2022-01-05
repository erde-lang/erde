-- Loader for `*.erde` files. Mutates the global require function.
local erde = require('erde')
local nativeRequire = require
-- TODO: figure out why global `package` not available in local require
local package = _G.package
local pathSep = package.config:sub(1, 1)

function require(moduleName)
  moduleName = moduleName:gsub('%.', pathSep)

  if package.loaded[moduleName] ~= nil then
    return package.loaded[moduleName]
  end

  for path in package.path:gmatch('[^;]+') do
    local erdePath = path:gsub('%.lua', '.erde'):gsub('?', moduleName)
    moduleFile = io.open(erdePath)

    if moduleFile ~= nil then
      local module = erde.run(moduleFile:read('*a'))

      -- Keep consistent behavior w/
      -- https://www.lua.org/manual/5.1/manual.html#pdf-require
      if module ~= nil then
        package.loaded[moduleName] = module
      else
        package.loaded[moduleName] = true
      end

      print(moduleName, module)
      return module
    end
  end

  return nativeRequire(moduleName)
end
