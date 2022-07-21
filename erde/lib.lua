-- This module contains higher level functions for use either via API or
-- internally (mostly in the CLI).

local C = require('erde.constants')
local compile = require('erde.compile')
local luaTarget = require('erde.luaTarget')
local utils = require('erde.utils')

local load = loadstring or load
local unpack = table.unpack or unpack

-- https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders
-- https://www.lua.org/manual/5.2/manual.html#pdf-package.searchers
local searchers = package.loaders or package.searchers

local sourceMapCache = {}

-- -----------------------------------------------------------------------------
-- Debug
-- -----------------------------------------------------------------------------

-- Patterns to remove from generated tracebacks. This is mostly to hide erde's
-- internal function calls, as they will be noisy to the user and possibly
-- misleading.
local TRACEBACK_FILTERS = {
  table.concat({
    "[^\n]*%[C]: in function 'xpcall'\n",
    "[^\n]*: in function '__erde_internal_run_string__'\n",
    '[^\n]*\n',
  }),
  table.concat({
    "[^\n]*%[C]: in function 'xpcall'\n",
    "[^\n]*: in function '__erde_internal_run_module__'\n",
    '[^\n]*\n',
  }),
}

local function rewrite(message, sourceMap, sourceAlias)
  -- Only rewrite strings! Other thrown values (including nil) do not get source
  -- and line number information added.
  if type(message) ~= 'string' then return message end
  local sourceFile, errLine, content = message:match('^(.*):(%d+): (.*)$')

  -- Explicitly check for these! Error messages may not contain source or line 
  -- number, for example if they are called w/ error level 0.
  -- see: https://www.lua.org/manual/5.1/manual.html#pdf-error
  if not sourceFile or not errLine then return message end

  -- Extract chunknames from `load` if it looks like:
  -- 1. an .erde file (from __erde_internal_run_module__)
  -- 2. an embedded `load` (from __erde_internal_run_string__)
  --
  -- TODO: Technically, these are not "safe" in the sense that a user defined
  -- chunkname may match one of these. Maybe need to make the matching more
  -- strict, for example by injecting a string (for example: `[string __erde_internal__ ./myfile.erde]`)
  -- but for now this is cleaner and should work 99.9% of the time.
  sourceAlias = sourceAlias or sourceFile:match('^%[string "(.+%.erde)"]$')
  sourceAlias = sourceAlias or sourceFile:match('^%[string "(%[string ".*"])"]$')

  -- TODO: if we detect we are rewriting a loaded erde string and there is no
  -- source map, indicate the line number is for compiled lua

  if sourceMap == nil then
    local erdeSourceFile = sourceFile:gsub('%.lua$', '.erde')
    -- TODO: use sourceMapCache
  end

  return ('%s:%d: %s'):format(
    sourceAlias or sourceFile,
    sourceMap ~= nil and sourceMap[tonumber(errLine)] or errLine,
    content
  )
end

-- Mimic of Lua's native `debug.traceback` w/ file and line number rewrites.
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
      table.insert(stack, '\t' .. rewrite(('%s:%d: in main chunk'):format(
        info.short_src,
        info.currentline
      )))
    elseif info.what == 'tail' then
      -- Group tail calls to prevent long stack traces. This matches the
      -- behavior in 5.2+, but will only ever happen in 5.1, since tail calls
      -- are not included in `debug.getinfo` levels in 5.2+.
      if not committedTailCallTrace then
        table.insert(stack, '\t(...tail calls...)')
      end
    elseif info.name then
      table.insert(stack, '\t' .. rewrite(("%s:%d: in function '%s'"):format(
        info.short_src,
        info.currentline,
        info.name
      )))
    else
      table.insert(stack, '\t' .. rewrite(('%s:%d: in function <%s:%d>'):format(
        info.short_src,
        info.currentline,
        info.short_src,
        info.linedefined
      )))
    end

    committedTailCallTrace = info.what == 'tail'
    level = level + 1
    info = debug.getinfo(level, 'nSl')
  end

  if C.IS_CLI_RUNTIME then
    -- Remove following from stack trace (caused by the CLI):
    -- [C]: in function 'xpcall'
    -- erde/bin/erde:xxx: in function 'runFile'
    -- erde/bin/erde:xxx: in main chunk
    local stackLen = #stack
    table.remove(stack, stackLen - 1)
    table.remove(stack, stackLen - 2)
    table.remove(stack, stackLen - 3)
  end

  local stacktrace = table.concat(stack, '\n')

  for _, filter in ipairs(TRACEBACK_FILTERS) do
    stacktrace = stacktrace:gsub(filter, '')
  end

  return stacktrace
end

local function pcallRewrite(callback, ...)
  local args = { ... }
  return xpcall(function() return callback(unpack(args)) end, rewrite)
end

local function xpcallRewrite(callback, msgh, ...)
  local args = { ... }
  return xpcall(
    function() return callback(unpack(args)) end,
    function(message) return msgh(rewrite(message)) end
  )
end

-- -----------------------------------------------------------------------------
-- Run
-- -----------------------------------------------------------------------------

-- Do not expose __erde_internal_run_string__ directly. We choose an odd naming
-- so that it is reliable searchable in stacktraces and we need a proxy between
-- the identifiable function and the exposed one in case the function is called
-- under a different name.
--
-- For example, if we do return `{ run = __erde_internal_run_string__ }` in this
-- module and the user calls `local x = require('erde').run`, the stacktrace
-- will show a call to `x` and we will lose the __erde_internal_run_string__
-- marker.
local function __erde_internal_run_string__(sourceCode, sourceAlias)
  if sourceAlias == nil then
    sourceAlias = sourceCode:sub(1, 6)

    if #sourceAlias > 5 then
      sourceAlias = sourceAlias:sub(1, 5) .. '...'
    end

    sourceAlias = ('[string "%s"]'):format(sourceAlias)
  end

  -- TODO: error handling here
  local compiled, sourceMap = compile(sourceCode)
  local loader, err = load(compiled, sourceAlias)

  local ok, result = xpcall(loader, function(message)
    if type(message) == 'table' and message.stacktrace then
      -- Do not unnecessarily wrap an error we have already handled!
      return message
    else
      message = rewrite(message, sourceMap, sourceAlias)
      -- Add an extra level to the traceback to account for the wrapping
      -- anonymous function above (in xpcall).
      return { message = message, stacktrace = traceback(message, 2) }
    end
  end)

  if not ok then error(result) end
  return result
end

local function runString(sourceCode, sourceAlias)
  -- DO NOT USE `return __erde_internal_run_string__(...)`
  --
  -- Lua recycles stacks in tail calls, which causes `__erde_internal_run_string__`
  -- to become unidentifiable in the stack trace. This is a problem, since we
  -- need to remove the `xpcall` and `__erde_internal_run_string__` calls from
  -- the stack trace before showing it to the user.
  --
  -- (see `TRACEBACK_FILTERS`)
  -- (see https://www.lua.org/pil/23.1.html on why retrieving the function name is tricky)
  local result = __erde_internal_run_string__(sourceCode, sourceAlias)
  return result
end

-- -----------------------------------------------------------------------------
-- Loader
-- -----------------------------------------------------------------------------

local function __erde_internal_run_module__(filePath)
  local sourceCode = utils.readFile(filePath)

  -- TODO: error handling here
  local compiled, sourceMap = compile(sourceCode)

  local loader, err = load(compiled, filePath)

  local ok, result = xpcall(loader, function(message)
    if type(message) == 'table' and message.stacktrace then
      -- Do not unnecessarily wrap an error we have already handled!
      return message
    else
      message = rewrite(message, sourceMap, filePath)
      -- Add an extra level to the traceback to account for the wrapping
      -- anonymous function above (in xpcall).
      return { message = message, stacktrace = traceback(message, 2) }
    end
  end)

  if not ok then error(result) end
  return result
end

local function erdeSearcher(moduleName)
  local modulePath = moduleName:gsub('%.', C.PATH_SEPARATOR)

  for path in package.path:gmatch('[^;]+') do
    local fullModulePath = path:gsub('%.lua', '.erde'):gsub('?', modulePath)
    local moduleFile = io.open(fullModulePath)

    if moduleFile ~= nil then
      moduleFile:close()

      return function()
        -- DO NOT USE `return __erde_internal_run_module__(...)`
        --
        -- Lua recycles stacks in tail calls, which causes `__erde_internal_run_module__`
        -- to become unidentifiable in the stack trace. This is a problem, since we
        -- need to remove the `xpcall` and `__erde_internal_run_module__` calls from
        -- the stack trace before showing it to the user.
        --
        -- (see `TRACEBACK_FILTERS`)
        -- (see https://www.lua.org/pil/23.1.html on why retrieving the function name is tricky)
        local result = __erde_internal_run_module__(fullModulePath)
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
  load = load,
  unload = unload,
}
