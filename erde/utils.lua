local _MODULE = {}
local PATH_SEPARATOR
do
	local __ERDE_TMP_2__
	__ERDE_TMP_2__ = require("erde.constants")
	PATH_SEPARATOR = __ERDE_TMP_2__["PATH_SEPARATOR"]
end
local function echo(...)
	return ...
end
_MODULE.echo = echo
local function split(s, separator)
	if separator == nil then
		separator = "%s"
	end
	local parts = {}
	for part in s:gmatch(("([^" .. tostring(separator) .. "]+)")) do
		table.insert(parts, part)
	end
	return parts
end
_MODULE.split = split
local function trim(s)
	return s:gsub("^%s*(.*)%s*$", "%1")
end
_MODULE.trim = trim
local function get_source_summary(source)
	local summary = trim(source):sub(1, 5)
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
	return table.concat({
		...,
	}, PATH_SEPARATOR):gsub(PATH_SEPARATOR .. "+", PATH_SEPARATOR)
end
_MODULE.join_paths = join_paths
return _MODULE
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
