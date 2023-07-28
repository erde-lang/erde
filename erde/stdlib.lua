local _MODULE = {}
local _native_coroutine = coroutine
local coroutine = {}
_MODULE.coroutine = coroutine
local _native_debug = debug
local debug = {}
_MODULE.debug = debug
local _native_io = io
local io = {}
_MODULE.io = io
local _native_math = math
local math = {}
_MODULE.math = math
local _native_os = os
local os = {}
_MODULE.os = os
local _native_package = package
local package = {}
_MODULE.package = package
local _native_string = string
local string = {}
_MODULE.string = string
local _native_table = table
local table = {}
_MODULE.table = table
local function load()
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
_MODULE.load = load
local function unload()
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
_MODULE.unload = unload
local function _kpairs_iter(a, i)
	local key, value = i, nil
	repeat
		key, value = next(a, key)
	until type(key) ~= "number"
	return key, value
end
local function kpairs(t)
	return _kpairs_iter, t, nil
end
_MODULE.kpairs = kpairs
function io.exists(path)
	local file = io.open(path, "r")
	if file == nil then
		return false
	end
	file:close()
	return true
end
function io.readfile(path)
	local file = assert(io.open(path, "r"))
	local content = assert(file:read("*a"))
	file:close()
	return content
end
function io.writefile(path, content)
	local file = assert(io.open(path, "w"))
	assert(file:write(content))
	file:close()
end
function math.clamp(x, min, max)
	return math.min(math.max(x, min), max)
end
function math.round(x)
	if x < 0 then
		return math.ceil(x - 0.5)
	else
		return math.floor(x + 0.5)
	end
end
function math.sign(x)
	if x < 0 then
		return -1
	elseif x > 0 then
		return 1
	else
		return 0
	end
end
function os.capture(cmd)
	local file = assert(io.popen(cmd, "r"))
	local stdout = assert(file:read("*a"))
	file:close()
	return stdout
end
function package.cinsert(...)
	local templates = package.split(package.cpath)
	table.insert(templates, ...)
	package.cpath = package.concat(templates)
end
function package.concat(templates, i, j)
	local template_separator = string.split(package.config, "\n")[2]
	return table.concat(templates, template_separator, i, j)
end
function package.cremove(position)
	local templates = package.split(package.cpath)
	local removed = table.remove(templates, position)
	package.cpath = package.concat(templates)
	return removed
end
function package.insert(...)
	local templates = package.split(package.path)
	table.insert(templates, ...)
	package.path = package.concat(templates)
end
function package.remove(position)
	local templates = package.split(package.path)
	local removed = table.remove(templates, position)
	package.path = package.concat(templates)
	return removed
end
function package.split(path)
	local template_separator = string.split(package.config, "\n")[2]
	return string.split(path, template_separator)
end
local function _string_chars_iter(a, i)
	i = i + 1
	local char = a:sub(i, i)
	if char ~= "" then
		return i, char
	end
end
function string.chars(s)
	return _string_chars_iter, s, 0
end
function string.escape(s)
	local result = {}
	for _, part in ipairs(string.split(s, "%%%%")) do
		part = part:gsub("^([().*?[^$+-])", "%%%1")
		part = part:gsub("([^%%])([().*?[^$+-])", "%1%%%2")
		part = part:gsub("%%([^%%().*?[^$+-])", "%%%%%1")
		part = part:gsub("%%$", "%%%%")
		table.insert(result, part)
	end
	return table.concat(result, "%%")
end
function string.lpad(s, length, padding)
	if padding == nil then
		padding = " "
	end
	return padding:rep(math.ceil((length - #s) / #padding)) .. s
end
function string.ltrim(s, pattern)
	if pattern == nil then
		pattern = "%s+"
	end
	local trimmed = s:gsub(("^" .. tostring(pattern)), "")
	return trimmed
end
function string.pad(s, length, padding)
	if padding == nil then
		padding = " "
	end
	local num_pads = math.ceil(((length - #s) / #padding) / 2)
	return padding:rep(num_pads) .. s .. padding:rep(num_pads)
end
function string.rpad(s, length, padding)
	if padding == nil then
		padding = " "
	end
	return s .. padding:rep(math.ceil((length - #s) / #padding))
end
function string.rtrim(s, pattern)
	if pattern == nil then
		pattern = "%s+"
	end
	local trimmed = s:gsub((tostring(pattern) .. "$"), "")
	return trimmed
end
function string.split(s, separator)
	if separator == nil then
		separator = "%s+"
	end
	local result = {}
	local i, j = s:find(separator)
	while i ~= nil do
		table.insert(result, s:sub(1, i - 1))
		s = s:sub(j + 1) or ""
		i, j = s:find(separator)
	end
	table.insert(result, s)
	return result
end
function string.trim(s, pattern)
	if pattern == nil then
		pattern = "%s+"
	end
	return string.ltrim(string.rtrim(s, pattern), pattern)
end
if _VERSION == "Lua 5.1" then
	table.pack = function(...)
		return {
			n = select("#", ...),
			...,
		}
	end
	table.unpack = unpack
end
function table.clear(t, callback)
	if type(callback) == "function" then
		for key, value in kpairs(t) do
			if callback(value, key) then
				t[key] = nil
			end
		end
		for i = #t, 1, -1 do
			if callback(t[i], i) then
				table.remove(t, i)
			end
		end
	else
		for key, value in kpairs(t) do
			if value == callback then
				t[key] = nil
			end
		end
		for i = #t, 1, -1 do
			if t[i] == callback then
				table.remove(t, i)
			end
		end
	end
end
function table.collect(...)
	local result = {}
	for key, value in ... do
		if value == nil then
			table.insert(result, key)
		else
			result[key] = value
		end
	end
	return result
end
function table.deepcopy(t)
	local result = {}
	for key, value in pairs(t) do
		if type(value) == "table" then
			result[key] = table.deepcopy(value)
		else
			result[key] = value
		end
	end
	return result
end
function table.empty(t)
	return next(t) == nil
end
function table.filter(t, callback)
	local result = {}
	for key, value in pairs(t) do
		if callback(value, key) then
			if type(key) == "number" then
				table.insert(result, value)
			else
				result[key] = value
			end
		end
	end
	return result
end
function table.find(t, callback)
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
function table.has(t, callback)
	local _, key = table.find(t, callback)
	return key ~= nil
end
function table.keys(t)
	local result = {}
	for key, value in pairs(t) do
		table.insert(result, key)
	end
	return result
end
function table.map(t, callback)
	local result = {}
	for key, value in pairs(t) do
		local newValue, newKey = callback(value, key)
		if newKey ~= nil then
			result[newKey] = newValue
		elseif type(key) == "number" then
			table.insert(result, newValue)
		else
			result[key] = newValue
		end
	end
	return result
end
function table.merge(t, ...)
	for _, _t in pairs({
		...,
	}) do
		for key, value in pairs(_t) do
			if type(key) == "number" then
				table.insert(t, value)
			else
				t[key] = value
			end
		end
	end
end
function table.reduce(t, initial, callback)
	local result = initial
	for key, value in pairs(t) do
		result = callback(result, value, key)
	end
	return result
end
function table.reverse(t)
	local len = #t
	for i = 1, math.floor(len / 2) do
		t[i], t[len - i + 1] = t[len - i + 1], t[i]
	end
end
function table.shallowcopy(t)
	local result = {}
	for key, value in pairs(t) do
		result[key] = value
	end
	return result
end
function table.slice(t, i, j)
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
	for i = math.max(i, 0), math.min(j, len) do
		table.insert(result, t[i])
	end
	return result
end
function table.values(t)
	local result = {}
	for key, value in pairs(t) do
		table.insert(result, value)
	end
	return result
end
setmetatable(coroutine, {
	__index = _native_coroutine,
	__newindex = _native_coroutine,
})
setmetatable(debug, {
	__index = _native_debug,
	__newindex = _native_debug,
})
setmetatable(io, {
	__index = _native_io,
	__newindex = _native_io,
})
setmetatable(math, {
	__index = _native_math,
	__newindex = _native_math,
})
setmetatable(os, {
	__index = _native_os,
	__newindex = _native_os,
})
setmetatable(package, {
	__index = _native_package,
	__newindex = _native_package,
})
setmetatable(string, {
	__index = _native_string,
	__newindex = _native_string,
})
setmetatable(table, {
	__index = _native_table,
	__newindex = _native_table,
})
return _MODULE
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
