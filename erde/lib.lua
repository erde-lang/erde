-- This module contains higher level functions for use either via API or
-- internally (mostly in the CLI).

local C = require('erde.constants')
local compile = require('erde.compile')
local utils = require('erde.utils')

local loadlua = loadstring or load
local unpack = table.unpack or unpack

-- https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders
-- https://www.lua.org/manual/5.2/manual.html#pdf-package.searchers
local searchers = package.loaders or package.searchers

local erde_source_id_counter = 1
local erde_source_cache = {}

-- -----------------------------------------------------------------------------
-- Debug
-- -----------------------------------------------------------------------------

local ERDE_INTERNAL_LOAD_SOURCE_STACKTRACE = table.concat({
  "[^\n]*%[C]: in function 'xpcall'\n",
  "[^\n]*: in function '__erde_internal_load_source__'\n",
  '[^\n]*\n',
})

local function rewrite(message, source_map, alias)
  -- Only rewrite strings! Other thrown values (including nil) do not get source
  -- and line number information added.
  if type(message) ~= 'string' then return message end
  local source, line, content = message:match('^(.*):(%d+): (.*)$')

  -- Explicitly check for these! Error messages may not contain source or line
  -- number, for example if they are called w/ error level 0.
  -- see: https://www.lua.org/manual/5.1/manual.html#pdf-error
  if not source or not line then return message end

  -- Use cached alias + source_map as a backup if they are not provided
  local erde_source_id = source:match('^%[string "(__erde_source_%d+__)"]$')
  if erde_source_id and erde_source_cache[erde_source_id] then
    alias = alias or erde_source_cache[erde_source_id].alias
    source_map = source_map or erde_source_cache[erde_source_id].source_map
  end

  -- If we have don't have a source_map for erde code, we need to indiciate that
  -- the error line is for the generated Lua.
  if erde_source_id and not source_map then
    line = ('(compiled: %s)'):format(line)
  end

  return ('%s:%s: %s'):format(
    alias or source,
    source_map and source_map[tonumber(line)] or line,
    content:gsub('__ERDE_SUBSTITUTE_([a-zA-Z]+)__', '%1')
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
  local committed_tail_call_trace = false

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
      if not committed_tail_call_trace then
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

    committed_tail_call_trace = info.what == 'tail'
    level = level + 1
    info = debug.getinfo(level, 'nSl')
  end

  if C.IS_CLI_RUNTIME and not C.DEBUG then
    -- Remove following from stack trace (caused by the CLI):
    -- [C]: in function 'xpcall'
    -- erde/bin/erde:xxx: in function 'run_file'
    -- erde/bin/erde:xxx: in main chunk
    local stacklen = #stack
    table.remove(stack, stacklen - 1)
    table.remove(stack, stacklen - 2)
    table.remove(stack, stacklen - 3)
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
-- Source Loaders
-- -----------------------------------------------------------------------------

-- Load a chunk of Erde code. This caches the generated source_map / alias
-- (see `erde_source_cache`) so we can fetch them later during error rewrites.
--
-- The alias is _not_ used as the chunkname in the underlying Lua `load`
-- call. Instead, a unique ID is generated and inserted instead. During error
-- rewrites, this ID will be extracted and replaced with the cached alias.
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
-- 2. Via `erde_searcher`
-- 3. Via `run_string`
--
-- Any changes to these functions and their stack calls should be done w/ great
-- precaution.
local function __erde_internal_load_source__(source, alias)
  local erde_source_id = ('__erde_source_%d__'):format(erde_source_id_counter)
  erde_source_id_counter = erde_source_id_counter + 1

  -- No xpcall here, we want the traceback to start from this stack!
  local ok, compiled, source_map = pcall(function()
    return compile(source)
  end)

  if not ok then
    local message = type(compiled) == 'table' and compiled.__is_erde_error__
      and ('%s:%d: %s'):format(alias, compiled.line or 0, compiled.message)
      or compiled

    utils.erde_error({
      type = 'compile',
      message = message,
      -- Use 3 levels to the traceback to account for the wrapping anonymous
      -- function above (in pcall) as well as the erde loader itself.
      stacktrace = traceback(message, 3),
    })
  end

  -- TODO: provide an option to disable source maps? Caching them prevents them
  -- from getting freed, and the tables (which may be potentially large) may
  -- have excessive memory usage on extremely constrained systems?
  erde_source_cache[erde_source_id] = { alias = alias, source_map = source_map }

  -- Remove the shebang! Lua's `load` function cannot handle shebangs.
  compiled = compiled:gsub('^#![^\n]+', '')

  local loader, err = loadlua(compiled, erde_source_id)

  if err ~= nil then
    utils.erde_error({
      type = 'run',
      message = table.concat({
        'Failed to load compiled code:',
        tostring(err),
        '',
        'This is an internal error that should never happen.',
        'Please report this at: https://github.com/erde-lang/erde/issues',
        '',
        'erde',
        '----',
        source,
        '',
        'lua',
        '---',
        compiled,
      }, '\n'),
    })
  end

  local ok, result = xpcall(loader, function(message)
    if type(message) == 'table' and message.__is_erde_error__ then
      -- Do not unnecessarily wrap an error we have already handled!
      return message
    else
      message = rewrite(message)
      return {
        type = 'run',
        message = message,
        -- Add an extra level to the traceback to account for the wrapping
        -- anonymous function above (in xpcall).
        stacktrace = traceback(message, 2),
      }
    end
  end)

  if not ok then utils.erde_error(result) end
  return result
end

-- IMPORTANT: THIS IS AN ERDE SOURCE LOADER AND MUST ADHERE TO THE USAGE SPEC OF
-- `__erde_internal_load_source__`!
local function run_string(source, alias)
  if alias == nil then
    alias = source:sub(1, 6)

    if #alias > 5 then
      alias = alias:sub(1, 5) .. '...'
    end

    alias = ('[string "%s"]'):format(alias)
  end

  local result = __erde_internal_load_source__(source, alias)
  return result
end

-- -----------------------------------------------------------------------------
-- Package Loader
-- -----------------------------------------------------------------------------

local function erde_searcher(module)
  local path = module:gsub('%.', C.PATH_SEPARATOR)

  for path in package.path:gmatch('[^;]+') do
    local fullpath = path:gsub('%.lua$', '.erde'):gsub('?', path)

    if utils.file_exists(fullpath) then
      -- IMPORTANT: THIS IS AN ERDE SOURCE LOADER AND MUST ADHERE TO THE USAGE SPEC OF
      -- `__erde_internal_load_source__`!
      return function()
        local source = utils.read_file(fullpath)
        local result = __erde_internal_load_source__(source, fullpath)
        return result
      end
    end
  end
end

local function load(new_lua_target, options)
  if new_lua_target ~= nil and C.VALID_LUA_TARGETS[new_lua_target] then
    C.LUA_TARGET = new_lua_target
  end

  if options then
    if options.debug then
      C.DEBUG = true
    end
  end

  for i, searcher in ipairs(searchers) do
    if searcher == erde_searcher then
      return
    end
  end

  -- We need to place the searcher before the `.lua` searcher to prioritize Erde
  -- modules over Lua modules. If the user has compiled an Erde project before
  -- but the compiled files are out of date, we need to avoid loading the
  -- outdated modules.
  table.insert(searchers, 2, erde_searcher)
end

local function unload()
  for i, searcher in ipairs(searchers) do
    if searcher == erde_searcher then
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
  run = run_string,
  load = load,
  unload = unload,
}
