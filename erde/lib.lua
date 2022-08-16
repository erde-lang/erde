-- This module contains higher level functions for use either via API or
-- internally (mostly in the CLI).

local C = require('erde.constants')
local compile = require('erde.compile')
local utils = require('erde.utils')

local load = loadstring or load
local unpack = table.unpack or unpack

-- https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders
-- https://www.lua.org/manual/5.2/manual.html#pdf-package.searchers
local searchers = package.loaders or package.searchers

local erdeSourceIdCounter = 1
local erdeSourceCache = {}

-- -----------------------------------------------------------------------------
-- Debug
-- -----------------------------------------------------------------------------

local ERDE_INTERNAL_LOAD_SOURCE_STACKTRACE = table.concat({
  "[^\n]*%[C]: in function 'xpcall'\n",
  "[^\n]*: in function '__erde_internal_load_source__'\n",
  '[^\n]*\n',
})

local function rewrite(message, sourceMap, sourceAlias)
  -- Only rewrite strings! Other thrown values (including nil) do not get source
  -- and line number information added.
  if type(message) ~= 'string' then return message end
  local sourceFile, errLine, content = message:match('^(.*):(%d+): (.*)$')

  -- Explicitly check for these! Error messages may not contain source or line 
  -- number, for example if they are called w/ error level 0.
  -- see: https://www.lua.org/manual/5.1/manual.html#pdf-error
  if not sourceFile or not errLine then return message end

  -- Use cached alias + sourceMap as a backup if they are not provided
  local erdeSourceId = sourceFile:match('^%[string "(__erde_source_%d+__)"]$')
  if erdeSourceId and erdeSourceCache[erdeSourceId] then
    sourceAlias = sourceAlias or erdeSourceCache[erdeSourceId].alias
    sourceMap = sourceMap or erdeSourceCache[erdeSourceId].sourceMap
  end

  -- If we have don't have a sourceMap for erde code, we need to indiciate that
  -- the error line is for the generated Lua.
  if erdeSourceId and not sourceMap then
    errLine = ('(compiled: %s)'):format(errLine)
  end

  return ('%s:%s: %s'):format(
    sourceAlias or sourceFile,
    sourceMap and sourceMap[tonumber(errLine)] or errLine,
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

  if C.IS_CLI_RUNTIME and not C.DEBUG then
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

  if not C.DEBUG then
    -- Remove any lines from `__erde_internal_load_source__` calls.
    -- See `__erde_internal_load_source__` for more details.
    stacktrace = stacktrace:gsub(ERDE_INTERNAL_LOAD_SOURCE_STACKTRACE, '')
  end

  return stacktrace
end

-- -----------------------------------------------------------------------------
-- Sources
-- -----------------------------------------------------------------------------

-- Load a chunk of Erde code. This caches the generated sourceMap / sourceAlias
-- (see `erdeSourceCache`) so we can fetch them later during error rewrites.
--
-- The sourceAlias is _not_ used as the chunkname in the underlying Lua `load`
-- call. Instead, a unique ID is generated and inserted instead. During error
-- rewrites, this ID will be extracted and replaced with the cached sourceAlias.
--
-- This function is also given a unique function name so that it is reliably
-- searchable in stacktraces. During stracetrace rewrites (see `traceback`), the
-- presence of this name dictates which lines we need to remove (see `ERDE_INTERNAL_LOAD_SOURCE_STACKTRACE`).
-- Otherwise, the resulting stacktraces will include function calls from this
-- file, which will be quite confusing and noisy for the end user.
--
-- IMPORTANT: THIS FUNCTION MUST NOT BE TAIL CALLED NOR DIRECTLY CALLED BY THE
-- USER AND IS ASSUMED TO BE CALLED AT THE TOP LEVEL OF LOADING ERDE SOURCE CODE.
--
-- Although we use a unique name here to find it in stacktraces, the actual
-- rewriting is much trickier. Because Lua will automatically collapse tail
-- calls in stacktraces, its hard to know how many lines of internal code
-- _before_ the call to `__erde_internal_load_source__` we need to remove.
--
-- Furthermore, finding the name of the function call is also nontrivial and
-- will actually get lost if this is directly called by the user, so it must
-- have at least one function call before it (even the Lua docs seem to mention
-- this in `debug.getinfo`, see https://www.lua.org/pil/23.1.html).
--
-- Thus, for consistency we always assume that this is never tail called and
-- it is called at the top level of loading erde source code, which ensures that
-- we always have the following 3 lines to remove:
--
-- 1. The `xpcall` in `__erde_internal_load_source__`
-- 2. The call to `__erde_internal_load_source__` itself
-- 3. The call that invoked `__erde_internal_load_source__`
--
-- Currently there are three ways for the user to load Erde code:
--
-- 1. Via the CLI (ex. `erde myfile.erde`)
-- 2. Via `erdeSearcher`
-- 3. Via `runString`
--
-- Any changes to these functions and their stack calls should be done w/ great
-- precaution.
local function __erde_internal_load_source__(sourceCode, sourceAlias)
  local erdeSourceId = ('__erde_source_%d__'):format(erdeSourceIdCounter)
  erdeSourceIdCounter = erdeSourceIdCounter + 1

  -- No xpcall here, we want the traceback to start from this stack!
  local ok, compiled, sourceMap = pcall(function()
    return compile(sourceCode)
  end)

  if not ok then
    local message = type(compiled) == 'table' and compiled.__is_erde_internal_load_error__ 
      and ('%s:%d: %s'):format(sourceAlias, compiled.line, compiled.message)
      or compiled

    error({
      -- Provide a flag so we don't rewrite messages multiple times (see above).
      __is_erde_internal_load_error__ = true,
      message = message,
      -- Add 2 extra levels to the traceback to account for the wrapping
      -- anonymous function above (in pcall) as well as the erde loader itself.
      stacktrace = traceback(message, 3),
    })
  end

  -- TODO: provide an option to disable source maps? Caching them prevents them
  -- from getting freed, and the tables (which may be potentially large) may
  -- have excessive memory usage on extremely constrained systems?
  erdeSourceCache[erdeSourceId] = { alias = sourceAlias, sourceMap = sourceMap }

  local ok, result = xpcall(load(compiled, erdeSourceId), function(message)
    if type(message) == 'table' and message.__is_erde_internal_load_error__ then
      -- Do not unnecessarily wrap an error we have already handled!
      return message
    else
      message = rewrite(message, sourceMap, sourceAlias)
      return {
        -- Provide a flag so we don't rewrite messages multiple times (see above).
        __is_erde_internal_load_error__ = true,
        message = message,
        -- Add an extra level to the traceback to account for the wrapping
        -- anonymous function above (in xpcall).
        stacktrace = traceback(message, 2),
      }
    end
  end)

  if not ok then error(result) end
  return result
end

-- IMPORTANT: THIS IS AN ERDE CODE LOADER AND MUST ADHERE TO THE USAGE SPEC OF
-- `__erde_internal_load_source__`!
local function runErdeString(sourceCode, sourceAlias)
  if sourceAlias == nil then
    sourceAlias = sourceCode:sub(1, 6)

    if #sourceAlias > 5 then
      sourceAlias = sourceAlias:sub(1, 5) .. '...'
    end

    sourceAlias = ('[string "%s"]'):format(sourceAlias)
  end

  local result = __erde_internal_load_source__(sourceCode, sourceAlias)
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

      -- IMPORTANT: THIS IS AN ERDE CODE LOADER AND MUST ADHERE TO THE USAGE SPEC OF
      -- `__erde_internal_load_source__`!
      return function()
        local sourceCode = utils.readFile(fullModulePath)
        local result = __erde_internal_load_source__(sourceCode, fullModulePath)
        return result
      end
    end
  end
end

local function load(newLuaTarget, options)
  if newLuaTarget ~= nil and C.VALID_LUA_TARGETS[newLuaTarget] then
    C.LUA_TARGET = newLuaTarget
  end

  if options then
    if options.debug then
      C.DEBUG = true
    end
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
  __erde_internal_load_source__ = __erde_internal_load_source__,
  rewrite = rewrite,
  traceback = traceback,
  run = runErdeString,
  load = load,
  unload = unload,
}
