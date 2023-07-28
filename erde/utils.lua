local _MODULE = {}
local lfs = require("lfs")
local PATH_SEPARATOR
do
	local __ERDE_TMP_4__
	__ERDE_TMP_4__ = require("erde.constants")
	PATH_SEPARATOR = __ERDE_TMP_4__["PATH_SEPARATOR"]
end
local io, string
do
	local __ERDE_TMP_7__
	__ERDE_TMP_7__ = require("erde.stdlib")
	io = __ERDE_TMP_7__["io"]
	string = __ERDE_TMP_7__["string"]
end
local function join_paths(...)
	local joined = table.concat({
		...,
	}, PATH_SEPARATOR):gsub(PATH_SEPARATOR .. "+", PATH_SEPARATOR)
	return joined
end
_MODULE.join_paths = join_paths
local function ensure_path_parents(path)
	local path_parts = string.split(path, PATH_SEPARATOR)
	for i = 1, #path_parts - 1 do
		local parent_path = table.concat(path_parts, PATH_SEPARATOR, 1, i)
		if not io.exists(parent_path) then
			lfs.mkdir(parent_path)
		end
	end
end
_MODULE.ensure_path_parents = ensure_path_parents
local function echo(...)
	return ...
end
_MODULE.echo = echo
local function get_source_summary(source)
	local summary = string.trim(source):sub(1, 5)
	if #source > 5 then
		summary = summary .. "..."
	end
	return summary
end
_MODULE.get_source_summary = get_source_summary
local function get_source_alias(source)
	return ('[string "' .. tostring(get_source_summary(source)) .. '"]')
end
_MODULE.get_source_alias = get_source_alias
return _MODULE
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
