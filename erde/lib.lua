local _MODULE = {}
local C = require("erde.constants")
local compile = require("erde.compile")
local utils = require("erde.utils")
local loadlua = loadstring or load
local unpack = table.unpack or unpack
local native_traceback = debug.traceback
local searchers = package.loaders or package.searchers
local erde_source_id_counter = 1
local erde_source_cache = {}
local function rewrite(message)
	if type(message) ~= "string" then
		return message
	end
	for erde_source_id, compiled_line in message:gmatch('%[string "(__erde_source_%d+__)"]:(%d+)') do
		local erde_source_alias = ('[string "' .. tostring(erde_source_id) .. '"]')
		local sourcemap = {}
		if erde_source_cache[erde_source_id] then
			erde_source_alias = erde_source_cache[erde_source_id].alias or erde_source_alias
			sourcemap = erde_source_cache[erde_source_id].sourcemap or sourcemap
		end
		message = message:gsub(
			('%[string "' .. tostring(erde_source_id) .. '"]:' .. tostring(compiled_line)),
			erde_source_alias
				.. ":"
				.. (sourcemap[tonumber(compiled_line)] or ("(compiled:" .. tostring(compiled_line) .. ")"))
		)
	end
	message = message:gsub("__ERDE_SUBSTITUTE_([a-zA-Z]+)__", "%1")
	return message
end
_MODULE.rewrite = rewrite
local function traceback(arg1, arg2, arg3)
	local stacktrace, level
	if type(arg1) == "thread" then
		level = arg3 or 1
		stacktrace = native_traceback(arg1, arg2, level + 1)
	else
		level = arg2 or 1
		stacktrace = native_traceback(arg1, level + 1)
	end
	if type(stacktrace) ~= "string" then
		return stacktrace
	end
	if level > -1 and C.IS_CLI_RUNTIME then
		local stack = utils.split(stacktrace, "\n")
		local stacklen = #stack
		for i = 1, 4 do
			table.remove(stack, stacklen - i)
		end
		stacktrace = table.concat(stack, "\n")
	end
	stacktrace = stacktrace:gsub(
		table.concat({
			"[^\n]*\n",
			"[^\n]*__erde_internal_load_source__[^\n]*\n",
			"[^\n]*\n",
		}),
		""
	)
	return rewrite(stacktrace)
end
_MODULE.traceback = traceback
local function __erde_internal_load_source__(source, options)
	if options == nil then
		options = {}
	end
	local alias = options.alias or utils.get_source_alias(source)
	local erde_source_id = ("__erde_source_" .. tostring(erde_source_id_counter) .. "__")
	erde_source_id_counter = erde_source_id_counter + 1
	local compiled, sourcemap = compile(source, {
		alias = alias,
		lua_target = options.lua_target,
		bitlib = options.bitlib,
	})
	erde_source_cache[erde_source_id] = {
		alias = alias,
	}
	if not C.DISABLE_SOURCE_MAPS and not options.disable_source_maps then
		erde_source_cache[erde_source_id].sourcemap = sourcemap
	end
	compiled = compiled:gsub("^#![^\n]+", "")
	local loader, load_error = loadlua(compiled, erde_source_id)
	if load_error ~= nil then
		error(table.concat({
			"Failed to load compiled code:",
			tostring(load_error),
			"",
			"This is an internal error that should never happen.",
			"Please report this at: https://github.com/erde-lang/erde/issues",
			"",
			"erde",
			"----",
			source,
			"",
			"lua",
			"---",
			compiled,
		}, "\n"))
	end
	return loader()
end
_MODULE.__erde_internal_load_source__ = __erde_internal_load_source__
local function run(source, options)
	return utils.echo(__erde_internal_load_source__(source, options))
end
_MODULE.run = run
local function erde_searcher(module_name)
	local module_path = module_name:gsub("%.", C.PATH_SEPARATOR)
	for path in package.path:gmatch("[^;]+") do
		local fullpath = path:gsub("%.lua$", ".erde"):gsub("?", module_path)
		if utils.file_exists(fullpath) then
			return function()
				local source = utils.read_file(fullpath)
				local result = {
					__erde_internal_load_source__(source, {
						alias = fullpath,
					}),
				}
				return unpack(result)
			end
		end
	end
end
local function load(arg1, arg2)
	local new_lua_target, options = nil, {}
	if type(arg1) == "string" then
		new_lua_target = arg1
	end
	if type(arg1) == "table" then
		options = arg1
	elseif type(arg2) == "table" then
		options = arg2
	end
	C.BITLIB = options.bitlib
	C.DISABLE_SOURCE_MAPS = options.disable_source_maps
	debug.traceback = options.keep_traceback == true and native_traceback or traceback
	if new_lua_target ~= nil then
		if C.VALID_LUA_TARGETS[new_lua_target] then
			C.LUA_TARGET = new_lua_target
		else
			error(table.concat({
				("Invalid Lua target: " .. tostring(new_lua_target)),
				("Must be one of: " .. tostring(table.concat(C.VALID_LUA_TARGETS, ", "))),
			}, "\n"))
		end
	elseif jit ~= nil then
		C.LUA_TARGET = "jit"
	else
		new_lua_target = _VERSION:match("Lua (%d%.%d)")
		if C.VALID_LUA_TARGETS[new_lua_target] then
			C.LUA_TARGET = new_lua_target
		else
			error(("Unsupported Lua version: " .. tostring(_VERSION)))
		end
	end
	for _, searcher in ipairs(searchers) do
		if searcher == erde_searcher then
			return
		end
	end
	table.insert(searchers, 2, erde_searcher)
end
_MODULE.load = load
local function unload()
	debug.traceback = native_traceback
	for i, searcher in ipairs(searchers) do
		if searcher == erde_searcher then
			table.remove(searchers, i)
			return
		end
	end
end
_MODULE.unload = unload
return _MODULE
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
