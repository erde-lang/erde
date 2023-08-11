local _MODULE = {}
local PATH_SEPARATOR
do
	local __ERDE_TMP_2__
	__ERDE_TMP_2__ = require("erde.constants")
	PATH_SEPARATOR = __ERDE_TMP_2__["PATH_SEPARATOR"]
end
local io, string
do
	local __ERDE_TMP_5__
	__ERDE_TMP_5__ = require("erde.stdlib")
	io = __ERDE_TMP_5__["io"]
	string = __ERDE_TMP_5__["string"]
end
local function echo(...)
	return ...
end
_MODULE.echo = echo
local function join_paths(...)
	local joined = table.concat({
		...,
	}, PATH_SEPARATOR):gsub(PATH_SEPARATOR .. "+", PATH_SEPARATOR)
	return joined
end
_MODULE.join_paths = join_paths
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
