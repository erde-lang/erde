local _MODULE = {}
local PATH_SEPARATOR
do
	local __ERDE_TMP_2__
	__ERDE_TMP_2__ = require("erde.constants")
	PATH_SEPARATOR = __ERDE_TMP_2__["PATH_SEPARATOR"]
end
local string
do
	local __ERDE_TMP_5__
	__ERDE_TMP_5__ = require("erde.stdlib")
	string = __ERDE_TMP_5__["string"]
end
local function file_exists(path)
	local file = io.open(path, "r")
	if file == nil then
		return false
	end
	file:close()
	return true
end
_MODULE.file_exists = file_exists
local function read_file(path)
	local file = io.open(path)
	if file == nil then
		error(("file does not exist: " .. tostring(path)))
	end
	local contents = file:read("*a")
	file:close()
	return contents
end
_MODULE.read_file = read_file
local function join_paths(...)
	local joined = table.concat({
		...,
	}, PATH_SEPARATOR):gsub(PATH_SEPARATOR .. "+", PATH_SEPARATOR)
	return joined
end
_MODULE.join_paths = join_paths
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
