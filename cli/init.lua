#!/usr/bin/env lua

local argparse = require('argparse')
local lfs = require('lfs')
local erde = require('erde')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

-- TODO: make this cross platform + error handling?
-- 1) path separator
-- 2) Stopping point (dont use $HOME?)
function getPackage()
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

  return (loadstring or load)(compiledPackage), packageRoot
end

function traverseDir(root, callback)
  for fileName in lfs.dir(root) do
    if fileName ~= '.' and fileName ~= '..' and fileName ~= 'package.erde' then
      local filePath = root .. '/' .. fileName
      local attributes = lfs.attributes(filePath)
      if attributes ~= nil then
        if attributes.mode == 'directory' then
          traverseDir(filePath, callback)
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

if args.compile then
  traverseDir(root, function(srcFilePath)
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
