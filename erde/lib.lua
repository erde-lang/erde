local _MODULE = {}
local compile = require("erde.compile")
local config = require("erde.config")
local PATH_SEPARATOR, VALID_LUA_TARGETS
do
	local __ERDE_TMP_6__
	__ERDE_TMP_6__ = require("erde.constants")
	PATH_SEPARATOR = __ERDE_TMP_6__["PATH_SEPARATOR"]
	VALID_LUA_TARGETS = __ERDE_TMP_6__["VALID_LUA_TARGETS"]
end
local io, string
do
	local __ERDE_TMP_9__
	__ERDE_TMP_9__ = require("erde.stdlib")
	io = __ERDE_TMP_9__["io"]
	string = __ERDE_TMP_9__["string"]
end
local echo, get_source_summary
do
	local __ERDE_TMP_12__
	__ERDE_TMP_12__ = require("erde.utils")
	echo = __ERDE_TMP_12__["echo"]
	get_source_summary = __ERDE_TMP_12__["get_source_summary"]
end
local loadlua = loadstring or load
local unpack = table.unpack or unpack
local native_traceback = debug.traceback
local searchers = package.loaders or package.searchers
local erde_source_cache = {}
local erde_source_id_counter = 1
local function rewrite(message)
	if type(message) ~= "string" then
		return message
	end
	for erde_source_id, chunkname, compiled_line in message:gmatch('%[string "erde::(%d+)::([^\n]+)"]:(%d+)') do
		local cache = erde_source_cache[tonumber(erde_source_id)] or {}
		local source_map = cache.source_map or {}
		local source_line = source_map[tonumber(compiled_line)] or ("(compiled:" .. tostring(compiled_line) .. ")")
		local match = string.escape(
			(
					'[string "erde::'
					.. tostring(erde_source_id)
					.. "::"
					.. tostring(chunkname)
					.. '"]:'
					.. tostring(compiled_line)
				)
		)
		message = cache.has_alias and message:gsub(match, chunkname .. ":" .. source_line)
			or message:gsub(match, ('[string "' .. tostring(chunkname) .. '"]:' .. tostring(source_line)))
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
	if level > -1 and config.is_cli_runtime then
		local stack = string.split(stacktrace, "\n")
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
	local chunkname = table.concat({
		"erde",
		erde_source_id_counter,
		options.alias or get_source_summary(source),
	}, "::")
	local compiled, source_map = compile(source, {
		alias = options.alias,
		lua_target = options.lua_target,
		bitlib = options.bitlib,
	})
	compiled = compiled:gsub("^#![^\n]+", "")
	local loader, load_error = loadlua(compiled, chunkname)
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
	erde_source_cache[erde_source_id_counter] = {
		has_alias = options.alias ~= nil,
	}
	if not config.disable_source_maps and not options.disable_source_maps then
		erde_source_cache[erde_source_id_counter].source_map = source_map
	end
	erde_source_id_counter = erde_source_id_counter + 1
	return loader()
end
_MODULE.__erde_internal_load_source__ = __erde_internal_load_source__
local function run(source, options)
	return echo(__erde_internal_load_source__(source, options))
end
_MODULE.run = run
local function erde_searcher(module_name)
	local module_path = module_name:gsub("%.", PATH_SEPARATOR)
	for path in package.path:gmatch("[^;]+") do
		local fullpath = path:gsub("%.lua$", ".erde"):gsub("?", module_path)
		if io.exists(fullpath) then
			return function()
				local source = io.readfile(fullpath)
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
	config.bitlib = options.bitlib
	config.disable_source_maps = options.disable_source_maps
	debug.traceback = options.keep_traceback == true and native_traceback or traceback
	if new_lua_target ~= nil then
		if VALID_LUA_TARGETS[new_lua_target] then
			config.lua_target = new_lua_target
		else
			error(table.concat({
				("Invalid Lua target: " .. tostring(new_lua_target)),
				("Must be one of: " .. tostring(table.concat(VALID_LUA_TARGETS, ", "))),
			}, "\n"))
		end
	elseif jit ~= nil then
		config.lua_target = "jit"
	else
		new_lua_target = _VERSION:match("Lua (%d%.%d)")
		if VALID_LUA_TARGETS[new_lua_target] then
			config.lua_target = new_lua_target
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
