local _MODULE = {}
local PATH_SEPARATOR
local __ERDE_TMP_2__ = require("erde.constants")
PATH_SEPARATOR = __ERDE_TMP_2__.PATH_SEPARATOR
local io, string
local __ERDE_TMP_5__ = require("erde.stdlib")
io = __ERDE_TMP_5__.io
string = __ERDE_TMP_5__.string
function _MODULE.echo(...)
	return ...
end
function _MODULE.join_paths(...)
	local joined = table.concat({
		...,
	}, PATH_SEPARATOR):gsub(PATH_SEPARATOR .. "+", PATH_SEPARATOR)
	return joined
end
function _MODULE.get_source_summary(source)
	local summary = string.trim(source):sub(1, 5)
	if #source > 5 then
		summary = summary .. "..."
	end
	return summary
end
function _MODULE.get_source_alias(source)
	return '[string "' .. tostring(_MODULE.get_source_summary(source)) .. '"]'
end
return _MODULE
-- Compiled with Erde 1.0.0-1 w/ Lua target 5.1+
-- __ERDE_COMPILED__
