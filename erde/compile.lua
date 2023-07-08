local config = require("erde.config")
local BINOP_ASSIGNMENT_TOKENS, BINOPS, BITOPS, BITLIB_METHODS, COMPILED_FOOTER_COMMENT, DIGIT, KEYWORDS, LEFT_ASSOCIATIVE, LUA_KEYWORDS, SURROUND_ENDS, TERMINALS, TOKEN_TYPES, UNOPS, VERSION
do
	local __ERDE_TMP_4__
	__ERDE_TMP_4__ = require("erde.constants")
	BINOP_ASSIGNMENT_TOKENS = __ERDE_TMP_4__["BINOP_ASSIGNMENT_TOKENS"]
	BINOPS = __ERDE_TMP_4__["BINOPS"]
	BITOPS = __ERDE_TMP_4__["BITOPS"]
	BITLIB_METHODS = __ERDE_TMP_4__["BITLIB_METHODS"]
	COMPILED_FOOTER_COMMENT = __ERDE_TMP_4__["COMPILED_FOOTER_COMMENT"]
	DIGIT = __ERDE_TMP_4__["DIGIT"]
	KEYWORDS = __ERDE_TMP_4__["KEYWORDS"]
	LEFT_ASSOCIATIVE = __ERDE_TMP_4__["LEFT_ASSOCIATIVE"]
	LUA_KEYWORDS = __ERDE_TMP_4__["LUA_KEYWORDS"]
	SURROUND_ENDS = __ERDE_TMP_4__["SURROUND_ENDS"]
	TERMINALS = __ERDE_TMP_4__["TERMINALS"]
	TOKEN_TYPES = __ERDE_TMP_4__["TOKEN_TYPES"]
	UNOPS = __ERDE_TMP_4__["UNOPS"]
	VERSION = __ERDE_TMP_4__["VERSION"]
end
local tokenize = require("erde.tokenize")
local get_source_alias
do
	local __ERDE_TMP_9__
	__ERDE_TMP_9__ = require("erde.utils")
	get_source_alias = __ERDE_TMP_9__["get_source_alias"]
end
local unpack = table.unpack or unpack
local arrow_function_expression, expression, block, statement
local tokens
local current_token_index
local current_token
local block_depth
local tmp_name_counter
local break_name
local has_continue
local has_module_declarations
local is_module_return_block, module_return_line
local is_varargs_block
local alias
local lua_target
local bitlib
local function throw(message, line)
	if line == nil then
		line = current_token.line
	end
	error((tostring(alias) .. ":" .. tostring(line) .. ": " .. tostring(message)), 0)
end
local function consume()
	local consumed_token_value = current_token.value
	current_token_index = current_token_index + 1
	current_token = tokens[current_token_index]
	return consumed_token_value
end
local function branch(token)
	if token == current_token.value then
		consume()
		return true
	end
end
local function expect(token, prevent_consume)
	if current_token.type == TOKEN_TYPES.EOF then
		throw(("unexpected eof (expected " .. tostring(token) .. ")"))
	end
	if token ~= current_token.value then
		throw(("expected '" .. tostring(token) .. "' got '" .. tostring(current_token.value) .. "'"))
	end
	if not prevent_consume then
		return consume()
	end
end
local function look_ahead(n)
	local token = tokens[current_token_index + n]
	return token and token.value or nil
end
local function look_past_surround(token_start_index)
	if token_start_index == nil then
		token_start_index = current_token_index
	end
	local surround_start_token = tokens[token_start_index]
	local surround_end = SURROUND_ENDS[surround_start_token.value]
	local surround_depth = 1
	local look_ahead_token_index = token_start_index + 1
	local look_ahead_token = tokens[look_ahead_token_index]
	repeat
		if look_ahead_token.type == TOKEN_TYPES.EOF then
			throw(("unexpected eof, missing '" .. tostring(surround_end) .. "'"), surround_start_token.line)
		end
		if look_ahead_token.value == surround_start_token.value then
			surround_depth = surround_depth + 1
		elseif look_ahead_token.value == surround_end then
			surround_depth = surround_depth - 1
		end
		look_ahead_token_index = look_ahead_token_index + 1
		look_ahead_token = tokens[look_ahead_token_index]
	until surround_depth == 0
	return look_ahead_token, look_ahead_token_index
end
local function new_tmp_name()
	tmp_name_counter = tmp_name_counter + 1
	return ("__ERDE_TMP_" .. tostring(tmp_name_counter) .. "__")
end
local function weave(t, separator)
	if separator == nil then
		separator = ","
	end
	local woven = {}
	local len = #t
	for i = 1, len - 1 do
		table.insert(woven, t[i])
		if type(t[i]) ~= "number" then
			table.insert(woven, separator)
		end
	end
	table.insert(woven, t[len])
	return woven
end
local function compile_binop(token, line, lhs, rhs)
	if bitlib and BITOPS[token] then
		local bitop = ("require('" .. tostring(bitlib) .. "')." .. tostring(BITLIB_METHODS[token]) .. "(")
		return {
			line,
			bitop,
			lhs,
			line,
			",",
			rhs,
			line,
			")",
		}
	elseif token == "!=" then
		return {
			lhs,
			line,
			"~=",
			rhs,
		}
	elseif token == "||" then
		return {
			lhs,
			line,
			"or",
			rhs,
		}
	elseif token == "&&" then
		return {
			lhs,
			line,
			"and",
			rhs,
		}
	elseif token == "//" then
		return (lua_target == "5.3" or lua_target == "5.3+" or lua_target == "5.4" or lua_target == "5.4+")
				and {
					lhs,
					line,
					token,
					rhs,
				}
			or {
				line,
				"math.floor(",
				lhs,
				line,
				"/",
				rhs,
				line,
				")",
			}
	else
		return {
			lhs,
			line,
			token,
			rhs,
		}
	end
end
local function list(callback, break_token)
	local list = {}
	repeat
		table.insert(list, callback() or nil)
	until not branch(",") or (break_token and current_token.value == break_token)
	return list
end
local function surround(open_char, close_char, callback)
	expect(open_char)
	local result = callback()
	expect(close_char)
	return result
end
local function surround_list(open_char, close_char, allow_empty, callback)
	return surround(open_char, close_char, function()
		if current_token.value ~= close_char or not allow_empty then
			return list(callback, close_char)
		end
	end)
end
local function name(no_transform)
	if current_token.type == TOKEN_TYPES.EOF then
		throw("unexpected eof")
	end
	if current_token.type ~= TOKEN_TYPES.WORD then
		throw(("unexpected token '" .. tostring(current_token.value) .. "'"))
	end
	if KEYWORDS[current_token.value] ~= nil then
		throw(("unexpected keyword '" .. tostring(current_token.value) .. "'"))
	end
	if TERMINALS[current_token.value] ~= nil then
		throw(("unexpected builtin '" .. tostring(current_token.value) .. "'"))
	end
	if LUA_KEYWORDS[current_token.value] and not no_transform then
		return ("__ERDE_SUBSTITUTE_" .. tostring(consume()) .. "__")
	else
		return consume()
	end
end
local function array_destructure(scope)
	local compile_lines = {}
	local compile_name = new_tmp_name()
	local names = {}
	local assignment_prefix = scope == "global" and "_G." or ""
	local array_index = 0
	surround_list("[", "]", false, function()
		array_index = array_index + 1
		local name_line, name = current_token.line, name()
		table.insert(names, name)
		local assignment_name = assignment_prefix .. name
		table.insert(compile_lines, name_line)
		table.insert(
			compile_lines,
			(tostring(assignment_name) .. " = " .. tostring(compile_name) .. "[" .. tostring(array_index) .. "]")
		)
		if branch("=") then
			table.insert(
				compile_lines,
				("if " .. tostring(assignment_name) .. " == nil then " .. tostring(assignment_name) .. " = ")
			)
			table.insert(compile_lines, expression())
			table.insert(compile_lines, "end")
		end
	end)
	return {
		compile_lines = compile_lines,
		compile_name = compile_name,
		names = names,
	}
end
local function map_destructure(scope)
	local compile_lines = {}
	local compile_name = new_tmp_name()
	local names = {}
	local assignment_prefix = scope == "global" and "_G." or ""
	surround_list("{", "}", false, function()
		local key_line, raw_key, key = current_token.line, current_token.value, name()
		local name = branch(":") and name() or key
		table.insert(names, name)
		local assignment_name = assignment_prefix .. name
		table.insert(compile_lines, key_line)
		table.insert(
			compile_lines,
			(tostring(assignment_name) .. " = " .. tostring(compile_name) .. "['" .. tostring(raw_key) .. "']")
		)
		if branch("=") then
			table.insert(
				compile_lines,
				("if " .. tostring(assignment_name) .. " == nil then " .. tostring(assignment_name) .. " = ")
			)
			table.insert(compile_lines, expression())
			table.insert(compile_lines, "end")
		end
	end)
	return {
		compile_lines = compile_lines,
		compile_name = compile_name,
		names = names,
	}
end
local function variable(scope)
	if current_token.value == "[" then
		return array_destructure(scope)
	elseif current_token.value == "{" then
		return map_destructure(scope)
	else
		return name()
	end
end
local function single_quote_string()
	return {
		current_token.line,
		"'" .. consume() .. "'",
	}
end
local function double_quote_string()
	consume()
	if current_token.type == TOKEN_TYPES.DOUBLE_QUOTE_STRING then
		return '"' .. consume()
	end
	local compile_lines = {}
	local content_line, content = current_token.line, ""
	repeat
		if current_token.type == TOKEN_TYPES.INTERPOLATION then
			if content ~= "" then
				table.insert(compile_lines, content_line)
				table.insert(compile_lines, '"' .. content .. '"')
			end
			table.insert(compile_lines, {
				"tostring(",
				surround("{", "}", expression),
				")",
			})
			content_line, content = current_token.line, ""
		else
			content = content .. consume()
		end
	until current_token.type == TOKEN_TYPES.DOUBLE_QUOTE_STRING
	if content ~= "" then
		table.insert(compile_lines, content_line)
		table.insert(compile_lines, '"' .. content .. '"')
	end
	consume()
	return weave(compile_lines, "..")
end
local function block_string()
	local start_quote = "[" .. current_token.equals .. "["
	local end_quote = "]" .. current_token.equals .. "]"
	consume()
	if current_token.type == TOKEN_TYPES.BLOCK_STRING then
		return start_quote .. end_quote
	end
	local compile_lines = {}
	local content_line, content = current_token.line, ""
	repeat
		if current_token.type == TOKEN_TYPES.INTERPOLATION then
			if content ~= "" then
				table.insert(compile_lines, content_line)
				table.insert(compile_lines, start_quote .. content .. end_quote)
			end
			table.insert(compile_lines, {
				"tostring(",
				surround("{", "}", expression),
				")",
			})
			content_line, content = current_token.line, ""
			if current_token.value:sub(1, 1) == "\n" then
				content = content .. "\n" .. consume()
			end
		else
			content = content .. consume()
		end
	until current_token.type == TOKEN_TYPES.BLOCK_STRING
	if content ~= "" then
		table.insert(compile_lines, content_line)
		table.insert(compile_lines, start_quote .. content .. end_quote)
	end
	consume()
	return weave(compile_lines, "..")
end
local function table_constructor()
	local compile_lines = {}
	surround_list("{", "}", true, function()
		if current_token.value == "[" then
			table.insert(compile_lines, "[")
			table.insert(compile_lines, surround("[", "]", expression))
			table.insert(compile_lines, "]")
			table.insert(compile_lines, expect("="))
		elseif look_ahead(1) == "=" then
			local key = name(true)
			if LUA_KEYWORDS[key] then
				table.insert(compile_lines, ("['" .. tostring(key) .. "']") .. consume())
			else
				table.insert(compile_lines, key .. consume())
			end
		end
		table.insert(compile_lines, expression())
		table.insert(compile_lines, ",")
	end)
	return {
		"{",
		compile_lines,
		"}",
	}
end
local function return_list()
	local look_ahead_limit_token, look_ahead_limit_token_index = look_past_surround()
	if look_ahead_limit_token.value == "->" or look_ahead_limit_token.value == "=>" then
		return arrow_function_expression()
	end
	local is_list = false
	for look_ahead_token_index = current_token_index + 1, look_ahead_limit_token_index - 1 do
		local look_ahead_token = tokens[look_ahead_token_index]
		if look_ahead_token.type == TOKEN_TYPES.SYMBOL and SURROUND_ENDS[look_ahead_token.value] then
			look_ahead_token, look_ahead_token_index = look_past_surround(look_ahead_token_index)
		end
		if look_ahead_token.type == TOKEN_TYPES.SYMBOL and look_ahead_token.value == "," then
			return weave(surround_list("(", ")", false, expression))
		end
	end
	return expression()
end
local function return_statement()
	if is_module_return_block then
		module_return_line = current_token.line
	end
	local compile_lines = {
		current_token.line,
		consume(),
	}
	if block_depth == 1 then
		if current_token.type ~= TOKEN_TYPES.EOF then
			if current_token.value == "(" then
				table.insert(compile_lines, return_list())
			else
				table.insert(compile_lines, weave(list(expression)))
			end
		end
		if current_token.type ~= TOKEN_TYPES.EOF then
			throw(("expected '<eof>', got '" .. tostring(current_token.value) .. "'"))
		end
	else
		if current_token.value ~= "}" then
			if current_token.value == "(" then
				table.insert(compile_lines, return_list())
			else
				table.insert(compile_lines, weave(list(expression)))
			end
		end
		if current_token.value ~= "}" then
			throw(("expected '}', got '" .. tostring(current_token.value) .. "'"))
		end
	end
	return compile_lines
end
local function parameters()
	local compile_lines = {}
	local names = {}
	local has_varargs = false
	surround_list("(", ")", true, function()
		if branch("...") then
			has_varargs = true
			table.insert(names, "...")
			if current_token.value ~= ")" then
				table.insert(compile_lines, ("local " .. tostring(name()) .. " = { ... }"))
			end
			branch(",")
			expect(")", true)
		else
			local var = variable()
			local name = type(var) == "string" and var or var.compile_name
			table.insert(names, name)
			if branch("=") then
				table.insert(compile_lines, ("if " .. tostring(name) .. " == nil then " .. tostring(name) .. " = "))
				table.insert(compile_lines, expression())
				table.insert(compile_lines, "end")
			end
			if type(var) == "table" then
				table.insert(compile_lines, "local " .. table.concat(var.names, ","))
				table.insert(compile_lines, var.compile_lines)
			end
		end
	end)
	return {
		names = names,
		compile_lines = compile_lines,
		has_varargs = has_varargs,
	}
end
local function function_block()
	local old_is_module_return_block = is_module_return_block
	local old_break_name = break_name
	is_module_return_block = false
	break_name = nil
	local compile_lines = block()
	is_module_return_block = old_is_module_return_block
	break_name = old_break_name
	return compile_lines
end
function arrow_function_expression()
	local compile_lines = {}
	local param_names = {}
	local old_is_varargs_block = is_varargs_block
	if current_token.value == "(" then
		local params = parameters()
		is_varargs_block = params.has_varargs
		param_names = params.names
		table.insert(compile_lines, params.compile_lines)
	else
		local var = variable()
		is_varargs_block = false
		if type(var) == "string" then
			table.insert(param_names, var)
		else
			table.insert(param_names, var.compile_name)
			table.insert(compile_lines, "local " .. table.concat(var.names, ","))
			table.insert(compile_lines, var.compile_lines)
		end
	end
	if current_token.value == "->" then
		consume()
	elseif current_token.value == "=>" then
		table.insert(param_names, 1, "self")
		consume()
	elseif current_token.value == nil then
		throw("unexpected eof (expected '->' or '=>')")
	else
		throw(("unexpected token '" .. tostring(current_token.value) .. "' (expected '->' or '=>')"))
	end
	table.insert(compile_lines, 1, ("function(" .. tostring(table.concat(param_names, ",")) .. ")"))
	if current_token.value == "{" then
		table.insert(compile_lines, surround("{", "}", function_block))
	elseif current_token.value == "(" then
		table.insert(compile_lines, {
			"return",
			return_list(),
		})
	else
		table.insert(compile_lines, {
			"return",
			expression(),
		})
	end
	is_varargs_block = old_is_varargs_block
	table.insert(compile_lines, "end")
	return compile_lines
end
local function function_statement()
	local compile_lines = {}
	local scope_line, scope = current_token.line, nil
	if current_token.value == "local" or current_token.value == "module" then
		scope = consume()
		table.insert(compile_lines, "local")
		table.insert(compile_lines, consume())
	elseif current_token.value == "global" then
		scope = consume()
		table.insert(compile_lines, consume())
	elseif current_token.value == "function" then
		table.insert(compile_lines, consume())
	else
		throw(("unexpected token '" .. tostring(current_token.value) .. "' (expected scope)"))
	end
	if scope == "module" then
		if block_depth > 1 then
			throw("module declarations must appear at the top level", scope_line)
		end
		has_module_declarations = true
	end
	local signature = name()
	local is_table_value = current_token.value == "."
	if scope == "global" then
		signature = "_G." .. signature
		is_table_value = true
	end
	while branch(".") do
		signature = signature .. "." .. name()
	end
	if branch(":") then
		is_table_value = true
		signature = signature .. ":" .. name()
	end
	if is_table_value and (scope == "local" or scope == "module") then
		throw("cannot use scopes for table values", scope_line)
	end
	table.insert(compile_lines, signature)
	local params = parameters()
	table.insert(compile_lines, "(" .. table.concat(params.names, ",") .. ")")
	table.insert(compile_lines, params.compile_lines)
	local old_is_varargs_block = is_varargs_block
	is_varargs_block = params.has_varargs
	table.insert(compile_lines, surround("{", "}", function_block))
	is_varargs_block = old_is_varargs_block
	table.insert(compile_lines, "end")
	if scope == "module" then
		table.insert(compile_lines, ("_MODULE." .. tostring(signature) .. " = " .. tostring(signature)))
	end
	return compile_lines
end
local function index_chain(base_compile_lines, has_trivial_base, require_chain)
	local chain = {}
	local is_function_call = false
	local has_trivial_chain = false
	local needs_block_compile = false
	local block_compile_name = new_tmp_name()
	local block_compile_lines = {
		("local " .. tostring(block_compile_name)),
	}
	while true do
		if current_token.value == "[" then
			has_trivial_chain = false
			table.insert(chain, {
				current_token.line,
				"[",
				surround("[", "]", expression),
				"]",
			})
		elseif current_token.value == "." then
			has_trivial_chain = false
			local field_line = current_token.line
			consume()
			local field_name = name(true)
			if LUA_KEYWORDS[field_name] then
				table.insert(chain, {
					field_line,
					("['" .. tostring(field_name) .. "']"),
				})
			else
				table.insert(chain, {
					field_line,
					"." .. field_name,
				})
			end
		elseif branch(":") then
			has_trivial_chain = false
			is_function_call = true
			local link = {
				current_token.line,
			}
			local method_name = name(true)
			expect("(", true)
			if not LUA_KEYWORDS[method_name] then
				table.insert(link, ":" .. method_name)
			else
				local arg_compile_lines = surround_list("(", ")", true, expression)
				if has_trivial_base and has_trivial_chain then
					table.insert(link, '["' .. method_name .. '"](')
					table.insert(link, ("['" .. tostring(method_name) .. "']("))
					table.insert(link, base_compile_lines)
				else
					needs_block_compile = true
					link.needs_intermediate = true
					table.insert(link, ("['" .. tostring(method_name) .. "'](" .. tostring(block_compile_name)))
				end
				if arg_compile_lines then
					table.insert(link, ",")
					table.insert(link, weave(arg_compile_lines))
				end
				table.insert(link, ")")
			end
			table.insert(chain, link)
		elseif current_token.value == "(" and current_token.line == tokens[current_token_index - 1].line then
			has_trivial_chain = false
			is_function_call = true
			local chain_len = #chain
			local preceding_compile_lines, preceding_compile_lines_len
			if chain_len > 0 then
				preceding_compile_lines = chain[chain_len]
				preceding_compile_lines_len = #preceding_compile_lines
			else
				preceding_compile_lines = base_compile_lines
				preceding_compile_lines_len = #base_compile_lines
				while type(preceding_compile_lines[preceding_compile_lines_len]) == "table" do
					preceding_compile_lines = preceding_compile_lines[preceding_compile_lines_len]
					preceding_compile_lines_len = #preceding_compile_lines
				end
			end
			local arg_compile_lines = surround_list("(", ")", true, expression)
			if not arg_compile_lines then
				preceding_compile_lines[preceding_compile_lines_len] = preceding_compile_lines[preceding_compile_lines_len]
					.. "()"
			else
				preceding_compile_lines[preceding_compile_lines_len] = preceding_compile_lines[preceding_compile_lines_len]
					.. "("
				table.insert(chain, {
					weave(arg_compile_lines),
					")",
				})
			end
		else
			break
		end
	end
	if require_chain and has_trivial_chain then
		if not current_token.value then
			throw("unexpected eof")
		else
			throw(("expected index chain, found '" .. tostring(current_token.value) .. "'"))
		end
	end
	for _, link in ipairs(chain) do
		if link.needs_intermediate then
			table.insert(block_compile_lines, block_compile_name .. "=")
			table.insert(block_compile_lines, base_compile_lines)
			base_compile_lines = {
				block_compile_name,
			}
		end
		table.insert(base_compile_lines, link)
	end
	return {
		base_compile_lines = base_compile_lines,
		is_function_call = is_function_call,
		needs_block_compile = needs_block_compile,
		block_compile_name = block_compile_name,
		block_compile_lines = block_compile_lines,
	}
end
local function index_chain_expression(...)
	local index_chain = index_chain(...)
	if not index_chain.needs_block_compile then
		return index_chain.base_compile_lines
	else
		return {
			"(function()",
			index_chain.block_compile_lines,
			"return",
			index_chain.base_compile_lines,
			"end)()",
		}
	end
end
local function terminal_expression()
	if current_token.type == TOKEN_TYPES.NUMBER then
		return {
			current_token.line,
			consume(),
		}
	elseif current_token.type == TOKEN_TYPES.SINGLE_QUOTE_STRING then
		return index_chain_expression({
			"(",
			single_quote_string(),
			")",
		}, true)
	elseif current_token.type == TOKEN_TYPES.DOUBLE_QUOTE_STRING then
		return index_chain_expression({
			"(",
			double_quote_string(),
			")",
		}, false)
	elseif current_token.type == TOKEN_TYPES.BLOCK_STRING then
		return index_chain_expression({
			"(",
			block_string(),
			")",
		}, false)
	end
	if TERMINALS[current_token.value] then
		if current_token.value == "..." and not is_varargs_block then
			throw("cannot use '...' outside a vararg function")
		end
		return {
			current_token.line,
			consume(),
		}
	end
	local next_token_value = look_ahead(1)
	local is_arrow_function = next_token_value == "->" or next_token_value == "=>"
	if not is_arrow_function and SURROUND_ENDS[current_token.value] then
		local past_surround_token = look_past_surround()
		is_arrow_function = past_surround_token.value == "->" or past_surround_token.value == "=>"
	end
	if is_arrow_function then
		return arrow_function_expression()
	elseif current_token.value == "{" then
		return table_constructor()
	elseif current_token.value == "(" then
		return index_chain_expression({
			"(",
			surround("(", ")", expression),
			")",
		}, false)
	else
		return index_chain_expression({
			current_token.line,
			name(),
		}, true)
	end
end
local function unop_expression()
	local unop_line, unop = current_token.line, UNOPS[consume()]
	local operand_line, operand = current_token.line, expression(unop.prec + 1)
	if unop.token == "~" then
		if bitlib then
			local bitop = ("require('" .. tostring(bitlib) .. "').bnot(")
			return {
				unop_line,
				bitop,
				operand_line,
				operand,
				unop_line,
				")",
			}
		elseif lua_target == "5.1+" or lua_target == "5.2+" then
			throw("must specify bitlib for compiling bit operations when targeting 5.1+ or 5.2+", unop_line)
		else
			return {
				unop_line,
				unop.token,
				operand_line,
				operand,
			}
		end
	elseif unop.token == "!" then
		return {
			unop_line,
			"not",
			operand_line,
			operand,
		}
	else
		return {
			unop_line,
			unop.token,
			operand_line,
			operand,
		}
	end
end
function expression(min_prec)
	if min_prec == nil then
		min_prec = 1
	end
	if current_token.type == TOKEN_TYPES.EOF then
		throw("unexpected eof (expected expression)")
	end
	local compile_lines = UNOPS[current_token.value] and unop_expression() or terminal_expression()
	local binop, binop_line = BINOPS[current_token.value], current_token.line
	while binop and binop.prec >= min_prec do
		if BITOPS[binop.token] and (lua_target == "5.1+" or lua_target == "5.2+") and not bitlib then
			throw("must specify bitlib for compiling bit operations when targeting 5.1+ or 5.2+", binop_line)
		end
		consume()
		local operand = binop.assoc == LEFT_ASSOCIATIVE and expression(binop.prec + 1) or expression(binop.prec)
		compile_lines = compile_binop(binop.token, binop_line, compile_lines, operand)
		binop, binop_line = BINOPS[current_token.value], current_token.line
	end
	return compile_lines
end
function block()
	local compile_lines = {}
	block_depth = block_depth + 1
	while current_token.value ~= "}" do
		table.insert(compile_lines, statement())
	end
	block_depth = block_depth - 1
	return compile_lines
end
local function do_statement()
	return {
		consume(),
		surround("{", "}", block),
		"end",
	}
end
local function break_statement()
	if break_name == nil then
		throw("cannot use 'break' outside of loop")
	end
	return consume()
end
local function continue_statement()
	if break_name == nil then
		throw("cannot use 'continue' outside of loop")
	end
	has_continue = true
	consume()
	if lua_target == "5.1" or lua_target == "5.1+" then
		return (tostring(break_name) .. " = false break")
	else
		return ("goto " .. tostring(break_name))
	end
end
local function loop_block()
	local old_break_name = break_name
	local old_has_continue = has_continue
	break_name = new_tmp_name()
	has_continue = false
	local compile_lines = block()
	if has_continue then
		if lua_target == "5.1" or lua_target == "5.1+" then
			table.insert(compile_lines, 1, ("local " .. tostring(break_name) .. " = true repeat"))
			table.insert(
				compile_lines,
				(tostring(break_name) .. " = false until true if " .. tostring(break_name) .. " then break end")
			)
		else
			table.insert(compile_lines, ("::" .. tostring(break_name) .. "::"))
		end
	end
	break_name = old_break_name
	has_continue = old_has_continue
	return compile_lines
end
local function for_loop_statement()
	local compile_lines = {}
	local pre_body_compile_lines = {}
	table.insert(compile_lines, consume())
	if look_ahead(1) == "=" then
		table.insert(compile_lines, name() .. consume())
		local expr_list_line = current_token.line
		local expr_list = list(expression)
		local expr_list_len = #expr_list
		if expr_list_len ~= 2 and expr_list_len ~= 3 then
			throw(("invalid numeric for, expected 2-3 expressions, got " .. tostring(expr_list_len)), expr_list_line)
		end
		table.insert(compile_lines, weave(expr_list))
	else
		local names = {}
		for _, var in ipairs(list(variable)) do
			if type(var) == "string" then
				table.insert(names, var)
			else
				table.insert(names, var.compile_name)
				table.insert(pre_body_compile_lines, "local " .. table.concat(var.names, ","))
				table.insert(pre_body_compile_lines, var.compile_lines)
			end
		end
		table.insert(compile_lines, weave(names))
		table.insert(compile_lines, expect("in"))
		table.insert(compile_lines, weave(list(expression)))
	end
	table.insert(compile_lines, "do")
	table.insert(compile_lines, pre_body_compile_lines)
	table.insert(compile_lines, surround("{", "}", loop_block))
	table.insert(compile_lines, "end")
	return compile_lines
end
local function repeat_until_statement()
	return {
		consume(),
		surround("{", "}", loop_block),
		expect("until"),
		expression(),
	}
end
local function while_loop_statement()
	return {
		consume(),
		expression(),
		"do",
		surround("{", "}", loop_block),
		"end",
	}
end
local function goto_jump_statement()
	if lua_target == "5.1" or lua_target == "5.1+" then
		throw("'goto' statements only compatibly with lua targets 5.2+, jit")
	end
	return {
		consume(),
		current_token.line,
		name(),
	}
end
local function goto_label_statement()
	if lua_target == "5.1" or lua_target == "5.1+" then
		throw("'goto' statements only compatibly with lua targets 5.2+, jit")
	end
	return consume() .. name() .. expect("::")
end
local function if_else_statement()
	local compile_lines = {}
	table.insert(compile_lines, consume())
	table.insert(compile_lines, expression())
	table.insert(compile_lines, "then")
	table.insert(compile_lines, surround("{", "}", block))
	while current_token.value == "elseif" do
		table.insert(compile_lines, consume())
		table.insert(compile_lines, expression())
		table.insert(compile_lines, "then")
		table.insert(compile_lines, surround("{", "}", block))
	end
	if current_token.value == "else" then
		table.insert(compile_lines, consume())
		table.insert(compile_lines, surround("{", "}", block))
	end
	table.insert(compile_lines, "end")
	return compile_lines
end
local function assignment_statement(first_id)
	local compile_lines = {}
	local index_chains = {
		first_id,
	}
	local base_compile_lines = {
		first_id.base_compile_lines,
	}
	local needs_block_compile = first_id.needs_block_compile
	while branch(",") do
		local index_chain_line = current_token.line
		local index_chain = current_token.value == "("
				and index_chain({
					"(",
					surround("(", ")", expression),
					")",
				}, false, true)
			or index_chain({
				name(),
			}, true)
		if index_chain.is_function_call then
			throw("cannot assign value to function call", index_chain_line)
		end
		needs_block_compile = needs_block_compile or index_chain.needs_block_compile
		table.insert(index_chains, index_chain)
		table.insert(base_compile_lines, index_chain.base_compile_lines)
	end
	local op_line, op_token = current_token.line, BINOP_ASSIGNMENT_TOKENS[current_token.value] and consume()
	if BITOPS[op_token] and (lua_target == "5.1+" or lua_target == "5.2+") and not bitlib then
		throw("must specify bitlib for compiling bit operations when targeting 5.1+ or 5.2+", op_line)
	end
	expect("=")
	local expr_list = list(expression)
	if not needs_block_compile and not op_token then
		table.insert(compile_lines, weave(base_compile_lines))
		table.insert(compile_lines, "=")
		table.insert(compile_lines, weave(expr_list))
	elseif not needs_block_compile and #index_chains == 1 then
		table.insert(compile_lines, first_id.base_compile_lines)
		table.insert(compile_lines, op_line)
		table.insert(compile_lines, "=")
		table.insert(compile_lines, compile_binop(op_token, op_line, first_id.base_compile_lines, expr_list[1]))
	else
		local assignment_names = {}
		local assignment_compile_lines = {}
		for _, id in ipairs(index_chains) do
			local assignment_name = new_tmp_name()
			table.insert(assignment_names, assignment_name)
			if id.needs_block_compile then
				table.insert(assignment_compile_lines, id.block_compile_lines)
			end
			table.insert(assignment_compile_lines, id.base_compile_lines)
			table.insert(assignment_compile_lines, "=")
			table.insert(
				assignment_compile_lines,
				op_token and compile_binop(op_token, op_line, id.base_compile_lines, assignment_name) or assignment_name
			)
		end
		table.insert(compile_lines, "do")
		table.insert(compile_lines, "local")
		table.insert(compile_lines, table.concat(assignment_names, ","))
		table.insert(compile_lines, "=")
		table.insert(compile_lines, weave(expr_list))
		table.insert(compile_lines, assignment_compile_lines)
		table.insert(compile_lines, "end")
	end
	return compile_lines
end
local function declaration_statement()
	local scope = consume()
	local compile_lines = {}
	local destructure_compile_lines = {}
	local declaration_names = {}
	local destructure_compile_names = {}
	local assignment_names = {}
	if scope == "module" then
		if block_depth > 1 then
			throw("module declarations must appear at the top level", tokens[current_token_index - 1].line)
		end
		has_module_declarations = true
	end
	for _, var in
		ipairs(list(function()
			return variable(scope)
		end))
	do
		if type(var) == "string" then
			table.insert(declaration_names, var)
			table.insert(assignment_names, (scope == "global" and "_G." or "") .. var)
		else
			table.insert(assignment_names, var.compile_name)
			table.insert(destructure_compile_names, var.compile_name)
			table.insert(destructure_compile_lines, var.compile_lines)
			for _, name in ipairs(var.names) do
				table.insert(declaration_names, name)
			end
		end
	end
	if scope ~= "global" then
		table.insert(compile_lines, "local " .. table.concat(declaration_names, ","))
	end
	if branch("=") then
		if #destructure_compile_names > 0 then
			table.insert(compile_lines, "do")
			table.insert(compile_lines, "local " .. table.concat(destructure_compile_names, ","))
			table.insert(compile_lines, table.concat(assignment_names, ",") .. "=")
			table.insert(compile_lines, weave(list(expression)))
			table.insert(compile_lines, destructure_compile_lines)
			table.insert(compile_lines, "end")
		elseif scope == "global" then
			table.insert(compile_lines, table.concat(assignment_names, ",") .. "=")
			table.insert(compile_lines, weave(list(expression)))
		else
			table.insert(compile_lines, "=")
			table.insert(compile_lines, weave(list(expression)))
		end
		if scope == "module" then
			local module_names = {}
			for _, declaration_name in ipairs(declaration_names) do
				table.insert(module_names, "_MODULE." .. declaration_name)
			end
			table.insert(
				compile_lines,
				("%s = %s"):format(table.concat(module_names, ","), table.concat(declaration_names, ","))
			)
		end
	end
	return compile_lines
end
function statement()
	local compile_lines = {}
	if current_token.value == "break" then
		table.insert(compile_lines, break_statement())
	elseif current_token.value == "continue" then
		table.insert(compile_lines, continue_statement())
	elseif current_token.value == "goto" then
		table.insert(compile_lines, goto_jump_statement())
	elseif current_token.value == "::" then
		table.insert(compile_lines, goto_label_statement())
	elseif current_token.value == "do" then
		table.insert(compile_lines, do_statement())
	elseif current_token.value == "if" then
		table.insert(compile_lines, if_else_statement())
	elseif current_token.value == "for" then
		table.insert(compile_lines, for_loop_statement())
	elseif current_token.value == "while" then
		table.insert(compile_lines, while_loop_statement())
	elseif current_token.value == "repeat" then
		table.insert(compile_lines, repeat_until_statement())
	elseif current_token.value == "return" then
		table.insert(compile_lines, return_statement())
	elseif current_token.value == "function" then
		table.insert(compile_lines, function_statement())
	elseif current_token.value == "local" or current_token.value == "global" or current_token.value == "module" then
		if look_ahead(1) == "function" then
			table.insert(compile_lines, function_statement())
		else
			table.insert(compile_lines, declaration_statement())
		end
	else
		local index_chain = current_token.value == "("
				and index_chain({
					current_token.line,
					"(",
					surround("(", ")", expression),
					")",
				}, false, true)
			or index_chain({
				current_token.line,
				name(),
			}, true)
		if not index_chain.is_function_call then
			table.insert(compile_lines, assignment_statement(index_chain))
		elseif not index_chain.needs_block_compile then
			table.insert(compile_lines, index_chain.base_compile_lines)
		else
			table.insert(compile_lines, {
				"(function()",
				index_chain.block_compile_lines,
				"return",
				index_chain.base_compile_lines,
				"end)()",
			})
		end
	end
	if current_token.value == ";" then
		table.insert(compile_lines, consume())
	elseif current_token.value == "(" then
		table.insert(compile_lines, ";")
	end
	return compile_lines
end
local function module_block()
	local compile_lines = {}
	if current_token.type == TOKEN_TYPES.SHEBANG then
		table.insert(compile_lines, consume())
	end
	while current_token.type ~= TOKEN_TYPES.EOF do
		table.insert(compile_lines, statement())
	end
	if has_module_declarations then
		if module_return_line ~= nil then
			throw("cannot use 'return' w/ 'module' declarations", module_return_line)
		end
		table.insert(compile_lines, 1, "local _MODULE = {}")
		table.insert(compile_lines, "return _MODULE")
	end
	return compile_lines
end
local function collect_compile_lines(lines, state)
	for _, line in ipairs(lines) do
		if type(line) == "number" then
			state.source_line = line
		elseif type(line) == "string" then
			table.insert(state.compile_lines, line)
			table.insert(state.source_map, state.source_line)
		else
			collect_compile_lines(line, state)
		end
	end
end
return function(source, options)
	if options == nil then
		options = {}
	end
	tokens = tokenize(source, options.alias)
	current_token_index = 1
	current_token = tokens[current_token_index]
	block_depth = 1
	tmp_name_counter = 1
	break_name = nil
	has_continue = false
	has_module_declarations = false
	is_module_return_block = true
	module_return_line = nil
	is_varargs_block = true
	alias = options.alias or get_source_alias(source)
	lua_target = options.lua_target or config.lua_target
	bitlib = options.bitlib
		or config.bitlib
		or (lua_target == "5.1" and "bit")
		or (lua_target == "jit" and "bit")
		or (lua_target == "5.2" and "bit32")
	local source_map = {}
	local compile_lines = {}
	collect_compile_lines(module_block(), {
		compile_lines = compile_lines,
		source_map = source_map,
		source_line = current_token.line,
	})
	table.insert(compile_lines, "-- Compiled with Erde " .. VERSION)
	table.insert(compile_lines, COMPILED_FOOTER_COMMENT)
	return table.concat(compile_lines, "\n"), source_map
end
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
