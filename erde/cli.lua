local lfs = require("lfs")
local compile = require("erde.compile")
local config = require("erde.config")
local COMPILED_FOOTER_COMMENT, VALID_LUA_TARGETS, VERSION
do
	local __ERDE_TMP_8__
	__ERDE_TMP_8__ = require("erde.constants")
	COMPILED_FOOTER_COMMENT = __ERDE_TMP_8__["COMPILED_FOOTER_COMMENT"]
	VALID_LUA_TARGETS = __ERDE_TMP_8__["VALID_LUA_TARGETS"]
	VERSION = __ERDE_TMP_8__["VERSION"]
end
local lib = require("erde.lib")
local string
do
	local __ERDE_TMP_13__
	__ERDE_TMP_13__ = require("erde.stdlib")
	string = __ERDE_TMP_13__["string"]
end
local file_exists, join_paths, read_file
do
	local __ERDE_TMP_16__
	__ERDE_TMP_16__ = require("erde.utils")
	file_exists = __ERDE_TMP_16__["file_exists"]
	join_paths = __ERDE_TMP_16__["join_paths"]
	read_file = __ERDE_TMP_16__["read_file"]
end
local unpack = table.unpack or unpack
local pack = table.pack or function(...)
	return {
		n = select("#", ...),
		...,
	}
end
local REPL_PROMPT = "> "
local REPL_SUB_PROMPT = ">> "
local HAS_READLINE, RL = pcall(function()
	return require("readline")
end)
local SUBCOMMANDS = {
	compile = true,
	clean = true,
	sourcemap = true,
}
local current_arg_index = 1
local num_args = #arg
local cli = {}
local script_args = {}
local function terminate(message, status)
	if status == nil then
		status = 1
	end
	print(message)
	os.exit(status)
end
local function parse_option(label)
	current_arg_index = current_arg_index + 1
	local arg_value = arg[current_arg_index]
	if not arg_value then
		terminate(("Missing argument for " .. tostring(label)))
	end
	return arg_value
end
local function traverse(paths, pattern, callback)
	for _, path in ipairs(paths) do
		local __ERDE_TMP_45__ = true
		repeat
			local attributes = lfs.attributes(path)
			if attributes == nil then
				__ERDE_TMP_45__ = false
				break
			end
			if attributes.mode == "file" then
				if path:match(pattern) then
					callback(path, attributes)
				end
			elseif attributes.mode == "directory" then
				local subpaths = {}
				for filename in lfs.dir(path) do
					if filename ~= "." and filename ~= ".." then
						table.insert(subpaths, join_paths(path, filename))
					end
				end
				traverse(subpaths, pattern, callback)
			end
			__ERDE_TMP_45__ = false
		until true
		if __ERDE_TMP_45__ then
			break
		end
	end
end
local function is_compiled_file(path)
	local file = io.open(path, "r")
	if file == nil then
		return false
	end
	local read_len = #COMPILED_FOOTER_COMMENT + 1
	file:seek("end", -read_len)
	local footer = file:read(read_len)
	file:close()
	return not not (footer and footer:find(COMPILED_FOOTER_COMMENT))
end
local HELP = (
	[[
Usage: erde [command] [args]

Commands:
   compile                Compile Erde files into Lua.
   clean                  Remove generated Lua files.
   sourcemap              Map a compiled (Lua) line to a source (Erde) line.

Options:
   -h, --help             Show this help message and exit.
   -v, --version          Show version and exit.
   -b, --bitlib <LIB>     Library to use for bit operations.
   -t, --target <TARGET>  Lua target for version compatability.
                          Must be one of: ]]
	.. tostring(table.concat(VALID_LUA_TARGETS, ", "))
	.. [[


Compile Options:
   -o, --outdir <DIR>     Output directory for compiled files.
   -w, --watch            Watch files and recompile on change.
   -f, --force            Force rewrite existing Lua files with compiled files.
   -p, --print            Print compiled code instead of writing to files.

Examples:
   erde
      Launch the REPL.

   erde my_script.erde
      Run my_script.erde.

   erde compile my_script.erde
      Compile my_script.erde (into my_script.lua).

   erde compile .
      Compile all *.erde files under the current directory.

   erde compile src -o dest
      Compile all *.erde files in src and place the *.lua files under dest.

   erde clean my_script.lua
      Remove my_script.lua if and only if it has been generated by `erde compile`.

   erde clean .
      Remove all generated *.lua files under the current directory.

   erde sourcemap my_script.erde 114
      Lookup which line in my_script.erde generated line 114 in my_script.lua.
]]
)
local function run_command()
	lib.load(cli.target)
	arg = script_args
	local ok, result = xpcall(function()
		local source = read_file(cli.script)
		local result = lib.__erde_internal_load_source__(source, {
			alias = cli.script,
		})
		return result
	end, lib.traceback)
	if not ok then
		terminate("erde: " .. result)
	end
end
local function compile_file(path)
	local compile_path = path:gsub("%.erde$", ".lua")
	if cli.outdir then
		compile_path = cli.outdir .. "/" .. compile_path
	end
	if not cli.print_compiled and not cli.force then
		if file_exists(compile_path) and not is_compiled_file(compile_path) then
			print((tostring(path) .. " => ERROR"))
			print(("Cannot write to " .. tostring(compile_path) .. ": file already exists"))
			return false
		end
	end
	local ok, result = pcall(function()
		return compile(read_file(path), {
			alias = path,
		})
	end)
	if not ok then
		print((tostring(path) .. " => ERROR"))
		if type(result == "table") and result.line then
			print(("erde:" .. tostring(result.line) .. ": " .. tostring(result.message)))
		else
			print(("erde: " .. tostring(result)))
		end
		return false
	end
	if cli.print_compiled then
		print(path)
		print(("-"):rep(#path))
		print(result)
	else
		local dest_file = io.open(compile_path, "w")
		dest_file:write(result)
		dest_file:close()
		if cli.watch then
			print(("[" .. tostring(os.date("%X")) .. "] " .. tostring(path) .. " => " .. tostring(compile_path)))
		else
			print((tostring(path) .. " => " .. tostring(compile_path)))
		end
	end
	return true
end
local function watch_files(cli)
	local modifications = {}
	local poll_interval = 1
	local has_socket, socket = pcall(function()
		return require("socket")
	end)
	local has_posix, posix = pcall(function()
		return require("posix.unistd")
	end)
	if not has_socket and not has_posix then
		print(table.concat({
			"WARNING: No libraries with sleep functionality found. This may ",
			"cause high CPU usage while watching. To fix this, you can install ",
			"either LuaSocket (https://luarocks.org/modules/luasocket/luasocket) ",
			"or luaposix (https://luarocks.org/modules/gvvaughan/luaposix)\n",
		}))
	end
	while true do
		traverse(cli, "%.erde$", function(path, attributes)
			if not modifications[path] or modifications[path] ~= attributes.modification then
				modifications[path] = attributes.modification
				compile_file(path, cli)
			end
		end)
		if has_socket then
			socket.sleep(poll_interval)
		elseif has_posix then
			posix.sleep(poll_interval)
		else
			local last_timeout = os.time()
			repeat
			until os.time() - last_timeout > poll_interval
		end
	end
end
local function compile_command()
	if #cli == 0 then
		table.insert(cli, ".")
	end
	if cli.watch then
		pcall(function()
			return watch_files(cli)
		end)
	else
		traverse(cli, "%.erde$", function(path)
			if not compile_file(path, cli) then
				os.exit(1)
			end
		end)
	end
end
local function clean_command()
	if #cli == 0 then
		table.insert(cli, ".")
	end
	traverse(cli, "%.lua$", function(path)
		if is_compiled_file(path) then
			os.remove(path)
			print((tostring(path) .. " => DELETED"))
		end
	end)
end
local function sourcemap_command()
	local path, line = cli[1], cli[2]
	if path == nil then
		terminate("Missing erde file to map")
	elseif line == nil then
		terminate("Missing line number to map")
	end
	local ok, result, sourcemap = pcall(function()
		return compile(read_file(path), {
			alias = path,
		})
	end)
	if ok then
		print((tostring(line) .. " => " .. tostring(sourcemap[tonumber(line)])))
	else
		print(("Failed to compile " .. tostring(path)))
		if type(result == "table") and result.line then
			print(("erde:" .. tostring(result.line) .. ": " .. tostring(result.message)))
		else
			print(("erde: " .. tostring(result)))
		end
	end
end
local function readline(prompt)
	if HAS_READLINE then
		return RL.readline(prompt)
	else
		io.write(prompt)
		return io.read()
	end
end
local function repl()
	print(("Erde " .. tostring(VERSION) .. " on " .. tostring(_VERSION) .. " -- Copyright (C) 2021-2023 bsuth"))
	if not HAS_READLINE then
		print("Install the `readline` Lua library to get support for arrow keys, keyboard shortcuts, history, etc.")
	end
	while true do
		local ok, result
		local source = readline(REPL_PROMPT)
		if not source or (HAS_READLINE and source == "(null)") then
			break
		end
		repeat
			ok, result = pcall(function()
				return pack(lib.run(("return " .. tostring(source)), {
					alias = "stdin",
				}))
			end)
			if not ok and type(result) == "string" and not result:find("unexpected eof") then
				ok, result = pcall(function()
					return pack(lib.run(source, {
						alias = "stdin",
					}))
				end)
			end
			if not ok and type(result) == "string" and result:find("unexpected eof") then
				repeat
					local subsource = readline(REPL_SUB_PROMPT)
					source = source .. subsource or ""
				until subsource
			end
		until ok or type(result) ~= "string" or not result:find("unexpected eof")
		if not ok then
			print(lib.rewrite(result))
		elseif result.n > 0 then
			for i = 1, result.n do
				result[i] = tostring(result[i])
			end
			print(unpack(result))
		end
		if HAS_READLINE and string.trim(source) ~= "" then
			RL.add_history(source)
		end
	end
end
local function repl_command()
	lib.load(cli.target)
	if HAS_READLINE then
		RL.set_readline_name("erde")
		RL.set_options({
			keeplines = 1000,
			histfile = "~/.erde_history",
			completion = false,
			auto_add = false,
		})
	end
	pcall(repl)
	if HAS_READLINE then
		RL.save_history()
	end
end
config.is_cli_runtime = true
while current_arg_index <= num_args do
	local arg_value = arg[current_arg_index]
	if cli.script then
		table.insert(script_args, arg_value)
	elseif not cli.subcommand and SUBCOMMANDS[arg_value] then
		cli.subcommand = arg_value
	elseif arg_value == "-h" or arg_value == "--help" then
		terminate(HELP, 0)
	elseif arg_value == "-v" or arg_value == "--version" then
		terminate(VERSION, 0)
	elseif arg_value == "-w" or arg_value == "--watch" then
		cli.watch = true
	elseif arg_value == "-f" or arg_value == "--force" then
		cli.force = true
	elseif arg_value == "-p" or arg_value == "--print" then
		cli.print_compiled = true
	elseif arg_value == "-t" or arg_value == "--target" then
		cli.target = parse_option(arg_value)
		config.lua_target = cli.target
		if not VALID_LUA_TARGETS[config.lua_target] then
			terminate(table.concat({
				("Invalid Lua target: " .. tostring(config.lua_target)),
				("Must be one of: " .. tostring(table.concat(VALID_LUA_TARGETS, ", "))),
			}, "\n"))
		end
	elseif arg_value == "-o" or arg_value == "--outdir" then
		cli.outdir = parse_option(arg_value)
	elseif arg_value == "-b" or arg_value == "--bitlib" then
		config.bitlib = parse_option(arg_value)
	elseif arg_value:sub(1, 1) == "-" then
		terminate(("Unrecognized option: " .. tostring(arg_value)))
	elseif not cli.subcommand and arg_value:match("%.erde$") then
		cli.script = arg_value
		script_args[-current_arg_index] = "erde"
		for i = 1, current_arg_index do
			script_args[-current_arg_index + i] = arg[i]
		end
	else
		table.insert(cli, arg_value)
	end
	current_arg_index = current_arg_index + 1
end
if cli.subcommand == "compile" then
	compile_command()
elseif cli.subcommand == "clean" then
	clean_command()
elseif cli.subcommand == "sourcemap" then
	sourcemap_command()
elseif not cli.script then
	repl_command()
elseif not file_exists(cli.script) then
	terminate(("File does not exist: " .. tostring(cli.script)))
else
	run_command()
end
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
