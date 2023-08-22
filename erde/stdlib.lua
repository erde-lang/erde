local _MODULE = {}
local _native_coroutine = coroutine
_MODULE.coroutine = {}
local _native_debug = debug
_MODULE.debug = {}
local _native_io = io
_MODULE.io = {}
local _native_math = math
_MODULE.math = {}
local _native_os = os
_MODULE.os = {}
local _native_package = package
_MODULE.package = {}
local _native_string = string
_MODULE.string = {}
local _native_table = table
_MODULE.table = {}
function _MODULE.load()
	for key, value in pairs(_MODULE) do
		local value_type = type(value)
		if value_type == "function" then
			if key ~= "load" and key ~= "unload" then
				_G[key] = value
			end
		elseif value_type == "table" then
			local library = _G[key]
			if type(library) == "table" then
				for subkey, subvalue in pairs(value) do
					library[subkey] = subvalue
				end
			end
		end
	end
end
function _MODULE.unload()
	for key, value in pairs(_MODULE) do
		local value_type = type(value)
		if value_type == "function" then
			if _G[key] == value then
				_G[key] = nil
			end
		elseif value_type == "table" then
			local library = _G[key]
			if type(library) == "table" then
				for subkey, subvalue in pairs(value) do
					if library[subkey] == subvalue then
						library[subkey] = nil
					end
				end
			end
		end
	end
end
local function _kpairs_iter(a, i)
	local key, value = i, nil
	repeat
		key, value = next(a, key)
	until type(key) ~= "number"
	return key, value
end
function _MODULE.kpairs(t)
	return _kpairs_iter, t, nil
end
function _MODULE.io.exists(path)
	local file = _MODULE.io.open(path, "r")
	if file == nil then
		return false
	end
	file:close()
	return true
end
function _MODULE.io.readfile(path)
	local file = assert(_MODULE.io.open(path, "r"))
	local content = assert(file:read("*a"))
	file:close()
	return content
end
function _MODULE.io.writefile(path, content)
	local file = assert(_MODULE.io.open(path, "w"))
	assert(file:write(content))
	file:close()
end
function _MODULE.math.clamp(x, min, max)
	return _MODULE.math.min(_MODULE.math.max(x, min), max)
end
function _MODULE.math.round(x)
	if x < 0 then
		return _MODULE.math.ceil(x - 0.5)
	else
		return _MODULE.math.floor(x + 0.5)
	end
end
function _MODULE.math.sign(x)
	if x < 0 then
		return -1
	elseif x > 0 then
		return 1
	else
		return 0
	end
end
function _MODULE.os.capture(cmd)
	local file = assert(_MODULE.io.popen(cmd, "r"))
	local stdout = assert(file:read("*a"))
	file:close()
	return stdout
end
function _MODULE.package.cinsert(...)
	local templates = _MODULE.package.split(_MODULE.package.cpath)
	_MODULE.table.insert(templates, ...)
	_MODULE.package.cpath = _MODULE.package.concat(templates)
end
function _MODULE.package.concat(templates, i, j)
	local template_separator = _MODULE.string.split(_MODULE.package.config, "\n")[2]
	return _MODULE.table.concat(templates, template_separator, i, j)
end
function _MODULE.package.cremove(position)
	local templates = _MODULE.package.split(_MODULE.package.cpath)
	local removed = _MODULE.table.remove(templates, position)
	_MODULE.package.cpath = _MODULE.package.concat(templates)
	return removed
end
function _MODULE.package.insert(...)
	local templates = _MODULE.package.split(_MODULE.package.path)
	_MODULE.table.insert(templates, ...)
	_MODULE.package.path = _MODULE.package.concat(templates)
end
function _MODULE.package.remove(position)
	local templates = _MODULE.package.split(_MODULE.package.path)
	local removed = _MODULE.table.remove(templates, position)
	_MODULE.package.path = _MODULE.package.concat(templates)
	return removed
end
function _MODULE.package.split(path)
	local template_separator = _MODULE.string.split(_MODULE.package.config, "\n")[2]
	return _MODULE.string.split(path, template_separator)
end
local function _string_chars_iter(a, i)
	i = i + 1
	local char = a:sub(i, i)
	if char ~= "" then
		return i, char
	end
end
function _MODULE.string.chars(s)
	return _string_chars_iter, s, 0
end
function _MODULE.string.escape(s)
	local escaped = s:gsub("[().%%+%-*?[^$]", "%%%1")
	return escaped
end
function _MODULE.string.lpad(s, length, padding)
	if padding == nil then
		padding = " "
	end
	return padding:rep(_MODULE.math.ceil((length - #s) / #padding)) .. s
end
function _MODULE.string.ltrim(s, pattern)
	if pattern == nil then
		pattern = "%s+"
	end
	local trimmed = s:gsub("^" .. tostring(pattern), "")
	return trimmed
end
function _MODULE.string.pad(s, length, padding)
	if padding == nil then
		padding = " "
	end
	local num_pads = _MODULE.math.ceil(((length - #s) / #padding) / 2)
	return padding:rep(num_pads) .. s .. padding:rep(num_pads)
end
function _MODULE.string.rpad(s, length, padding)
	if padding == nil then
		padding = " "
	end
	return s .. padding:rep(_MODULE.math.ceil((length - #s) / #padding))
end
function _MODULE.string.rtrim(s, pattern)
	if pattern == nil then
		pattern = "%s+"
	end
	local trimmed = s:gsub(tostring(pattern) .. "$", "")
	return trimmed
end
function _MODULE.string.split(s, separator)
	if separator == nil then
		separator = "%s+"
	end
	local result = {}
	local i, j = s:find(separator)
	while i ~= nil do
		_MODULE.table.insert(result, s:sub(1, i - 1))
		s = s:sub(j + 1) or ""
		i, j = s:find(separator)
	end
	_MODULE.table.insert(result, s)
	return result
end
function _MODULE.string.trim(s, pattern)
	if pattern == nil then
		pattern = "%s+"
	end
	return _MODULE.string.ltrim(_MODULE.string.rtrim(s, pattern), pattern)
end
if _VERSION == "Lua 5.1" then
	_MODULE.table.pack = function(...)
		return {
			n = select("#", ...),
			...,
		}
	end
	_MODULE.table.unpack = unpack
end
function _MODULE.table.clear(t, callback)
	if type(callback) == "function" then
		for key, value in _MODULE.kpairs(t) do
			if callback(value, key) then
				t[key] = nil
			end
		end
		for i = #t, 1, -1 do
			if callback(t[i], i) then
				_MODULE.table.remove(t, i)
			end
		end
	else
		for key, value in _MODULE.kpairs(t) do
			if value == callback then
				t[key] = nil
			end
		end
		for i = #t, 1, -1 do
			if t[i] == callback then
				_MODULE.table.remove(t, i)
			end
		end
	end
end
function _MODULE.table.collect(...)
	local result = {}
	for key, value in ... do
		if value == nil then
			_MODULE.table.insert(result, key)
		else
			result[key] = value
		end
	end
	return result
end
function _MODULE.table.deepcopy(t)
	local result = {}
	for key, value in pairs(t) do
		if type(value) == "table" then
			result[key] = _MODULE.table.deepcopy(value)
		else
			result[key] = value
		end
	end
	return result
end
function _MODULE.table.empty(t)
	return next(t) == nil
end
function _MODULE.table.filter(t, callback)
	local result = {}
	for key, value in pairs(t) do
		if callback(value, key) then
			if type(key) == "number" then
				_MODULE.table.insert(result, value)
			else
				result[key] = value
			end
		end
	end
	return result
end
function _MODULE.table.find(t, callback)
	if type(callback) == "function" then
		for key, value in pairs(t) do
			if callback(value, key) then
				return value, key
			end
		end
	else
		for key, value in pairs(t) do
			if value == callback then
				return value, key
			end
		end
	end
end
function _MODULE.table.has(t, callback)
	local _, key = _MODULE.table.find(t, callback)
	return key ~= nil
end
function _MODULE.table.keys(t)
	local result = {}
	for key, value in pairs(t) do
		_MODULE.table.insert(result, key)
	end
	return result
end
function _MODULE.table.map(t, callback)
	local result = {}
	for key, value in pairs(t) do
		local newValue, newKey = callback(value, key)
		if newKey ~= nil then
			result[newKey] = newValue
		elseif type(key) == "number" then
			_MODULE.table.insert(result, newValue)
		else
			result[key] = newValue
		end
	end
	return result
end
function _MODULE.table.merge(t, ...)
	for _, _t in pairs({
		...,
	}) do
		for key, value in pairs(_t) do
			if type(key) == "number" then
				_MODULE.table.insert(t, value)
			else
				t[key] = value
			end
		end
	end
end
function _MODULE.table.reduce(t, initial, callback)
	local result = initial
	for key, value in pairs(t) do
		result = callback(result, value, key)
	end
	return result
end
function _MODULE.table.reverse(t)
	local len = #t
	for i = 1, _MODULE.math.floor(len / 2) do
		t[i], t[len - i + 1] = t[len - i + 1], t[i]
	end
end
function _MODULE.table.shallowcopy(t)
	local result = {}
	for key, value in pairs(t) do
		result[key] = value
	end
	return result
end
function _MODULE.table.slice(t, i, j)
	if i == nil then
		i = 1
	end
	if j == nil then
		j = #t
	end
	local result, len = {}, #t
	if i < 0 then
		i = i + len + 1
	end
	if j < 0 then
		j = j + len + 1
	end
	for i = _MODULE.math.max(i, 0), _MODULE.math.min(j, len) do
		_MODULE.table.insert(result, t[i])
	end
	return result
end
function _MODULE.table.values(t)
	local result = {}
	for key, value in pairs(t) do
		_MODULE.table.insert(result, value)
	end
	return result
end
setmetatable(_MODULE.coroutine, {
	__index = _native_coroutine,
	__newindex = _native_coroutine,
})
setmetatable(_MODULE.debug, {
	__index = _native_debug,
	__newindex = _native_debug,
})
setmetatable(_MODULE.io, {
	__index = _native_io,
	__newindex = _native_io,
})
setmetatable(_MODULE.math, {
	__index = _native_math,
	__newindex = _native_math,
})
setmetatable(_MODULE.os, {
	__index = _native_os,
	__newindex = _native_os,
})
setmetatable(_MODULE.package, {
	__index = _native_package,
	__newindex = _native_package,
})
setmetatable(_MODULE.string, {
	__index = _native_string,
	__newindex = _native_string,
})
setmetatable(_MODULE.table, {
	__index = _native_table,
	__newindex = _native_table,
})
return _MODULE
-- Compiled with Erde 1.0.0-1 w/ Lua target 5.1+
-- __ERDE_COMPILED__
