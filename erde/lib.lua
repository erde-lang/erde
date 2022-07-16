-- This module contains higher level functions for use either via API or
-- internally (mostly in the CLI).

local C = require('erde.constants')
local compile = require('erde.compile')
local luaTarget = require('erde.luaTarget')

local load = loadstring or load
local unpack = table.unpack or unpack

-- https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders
-- https://www.lua.org/manual/5.2/manual.html#pdf-package.searchers
local searchers = package.loaders or package.searchers

local sourceMapCache = {}

-- -----------------------------------------------------------------------------
-- Debug
-- -----------------------------------------------------------------------------

local function rewrite(err, sourceMap, sourceName)
  -- Only rewrite string errors! Other thrown values (including nil) do not get
  -- source and line number information added.
  if type(err) ~= 'string' then return err end
  errSource, errLine, errMsg = err:match('^(.*):(%d+): (.*)$')

  -- Explicitly check for these! Error strings may not contain source or line 
  -- number, for example if they are called w/ error level 0.
  -- see: https://www.lua.org/manual/5.1/manual.html#pdf-error
  if errSource and errLine then
    errLine = tonumber(errLine)

    if sourceMap == nil then
      local erdeSource = errSource:gsub('%.lua$', '.erde')
      -- TODO: use sourceMapCache
    end

    return ('%s:%d: %s'):format(
      sourceName or errSource,
      sourceMap ~= nil and sourceMap[errLine] or errLine,
      errMsg
    )
  end
end

-- Simplified version of Lua's native `debug.traceback` based on the example
-- here: https://www.lua.org/pil/23.1.html
--
-- Unlike Lua's standard library, we do not accept a thread argument. See
-- https://www.lua.org/manual/5.4/manual.html#pdf-debug.traceback for behavior
-- specs.
--
-- TODO: Support thread argument?
local function traceback(message, level)
  -- Add an extra level to account for this traceback function itself!
  level = (level or 1) + 1

  if message and type(message) ~= 'string' then
    -- Do not do any processing if message is non-null and not a string. This
    -- mimics the standard `debug.traceback` behavior.
    return message
  end

  local stack = { message, 'stack traceback:' }
  local info = debug.getinfo(level, 'nSl')
  local committedTailCallTrace = false

  while info do
    local trace
    if info.what == 'C' then
      if info.name then
        table.insert(stack, ("\t[C]: in function '%s'"):format(info.name))
      else
        -- Use just '?' (matches Lua 5.1 behavior). Prefer not to use 'in ?'
        -- for consistency, since LuaJIT replaces this w/ the memory address,
        -- which takes the form 'at 0xXXX'.
        table.insert(stack, ('\t[C]: ?'):format(info.name))
      end
    elseif info.what == 'main' then
      table.insert(stack, ('\t%s:%d: in main chunk'):format(
        info.short_src,
        info.currentline
      ))
    elseif info.what == 'tail' then
      -- Group tail calls to prevent long stack traces. This matches the
      -- behavior in 5.2+, but will only ever happen in 5.1, since tail calls
      -- are not included in `debug.getinfo` levels in 5.2+.
      if not committedTailCallTrace then
        table.insert(stack, '\t(...tail calls...)')
      end
    elseif info.name then
      table.insert(stack, ("\t%s:%d: in function '%s'"):format(
        info.short_src,
        info.currentline,
        info.name
      ))
    else
      table.insert(stack, ("\t%s:%d: in function <%s:%d>"):format(
        info.short_src,
        info.currentline,
        info.short_src,
        info.linedefined
      ))
    end

    committedTailCallTrace = info.what == 'tail'
    level = level + 1
    info = debug.getinfo(level, 'nSl')
  end

  return table.concat(stack, '\n')
end

local function pcallRewrite(callback, ...)
  local args = { ... }
  return xpcall(function() return callback(unpack(args)) end, rewrite)
end

local function xpcallRewrite(callback, errHandler, ...)
  local args = { ... }
  return xpcall(
    function() return callback(unpack(args)) end,
    function(err) return errHandler(rewrite(err)) end
  )
end

-- -----------------------------------------------------------------------------
-- Run
-- -----------------------------------------------------------------------------

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
    -- Pass in error level 0 to avoid prefixing the rewritten error again!
    -- https://www.lua.org/manual/5.1/manual.html#pdf-error
    error(rewrite(result, sourceMap, sourceName), 0)
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
  sourceMapCache[filePath] = sourceMap

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
  pcallRewrite = pcallRewrite,
  xpcallRewrite = xpcallRewrite,
  runString = runString,
  runFile = runFile,
  load = load,
  unload = unload,
}
