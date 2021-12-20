#!/usr/bin/env lua

local argparse = require('argparse')
local lfs = require('lfs')
local erde = require('erde')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function contains(t, element)
  for i, value in ipairs(t) do
    if value == element then
      return true
    end
  end

  return false
end

-- TODO: make this cross platform + error handling?
-- 1) path separator
-- 2) Stopping point (dont use $HOME?)
local function getPackage()
  local home = os.getenv('HOME')
  local restoreDir = lfs.currentdir()

  local packageRoot = restoreDir
  local packageFile = io.open(packageRoot .. '/package.erde')
  while packageFile == nil and packageRoot:find(home) do
    lfs.chdir('..')
    packageRoot = lfs.currentdir()
    packageFile = io.open(packageRoot .. '/package.erde')
  end

  lfs.chdir(restoreDir)

  if packageFile == nil then
    return nil, nil
  end

  local packageContents = packageFile:read('*a')
  packageFile:close()
  local parsedPackage = erde.parse(packageContents)
  local compiledPackage = erde.compile(parsedPackage)

  local loadedPackage = (loadstring or load)(compiledPackage)
  if not loadedPackage then
    return nil, nil
  end

  return loadedPackage(), packageRoot
end

local function traverseDir(root, excludeDirs, callback)
  for fileName in lfs.dir(root) do
    if fileName ~= '.' and fileName ~= '..' and fileName ~= 'package.erde' then
      local filePath = root .. '/' .. fileName
      local attributes = lfs.attributes(filePath)

      if attributes ~= nil then
        if attributes.mode == 'directory' then
          if not contains(excludeDirs, filePath) then
            traverseDir(filePath, excludeDirs, callback)
          end
        elseif attributes.mode == 'file' and filePath:match('%.erde$') then
          callback(filePath)
        end
      end
    end
  end
end

-- -----------------------------------------------------------------------------
-- CLI
-- -----------------------------------------------------------------------------

local cli = argparse('erde')
cli:add_complete()
cli:option('-v --version')
cli:option('-l --luaVersion')

local compile = cli:command('compile')
compile:option('--root')

local run = cli:command('run')
local format = cli:command('format')

-- -----------------------------------------------------------------------------
-- Main
-- -----------------------------------------------------------------------------

local args = cli:parse()
local package, packageRoot = getPackage()
local root = args.root or packageRoot or lfs.currentdir()

if args.run then
elseif args.compile then
  local includeDirs = { root }
  local excludeDirs = {}

  if package and package.compile then
    if type(package.compile.include) == 'table' then
      for i, includeDir in ipairs(package.compile.include) do
        includeDirs[i] = root .. '/' .. includeDir
      end
    end

    if type(package.compile.exclude) == 'table' then
      for i, excludeDir in ipairs(package.compile.exclude) do
        excludeDirs[i] = root .. '/' .. excludeDir
      end
    end
  end

  for i, includeDir in ipairs(includeDirs) do
    traverseDir(includeDir, excludeDirs, function(srcFilePath)
      local srcFile = io.open(srcFilePath, 'r')
      local moduleContents = srcFile:read('*a')
      srcFile:close()
      local parsedModule = erde.parse(moduleContents)
      local compiledModule = erde.compile(parsedModule)

      local destFilePath = srcFilePath:gsub('.erde$', '.lua')
      local destFile = io.open(destFilePath, 'w')
      destFile:write(compiledModule)

      print(srcFilePath .. ' -> ' .. destFilePath)
    end)
  end
end
