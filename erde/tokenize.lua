local config = require("erde.config")
local DIGIT, HEX, STANDARD_ESCAPE_CHARS, SYMBOLS, TOKEN_TYPES, WORD_BODY, WORD_HEAD
do
	local __ERDE_TMP_4__
	__ERDE_TMP_4__ = require("erde.constants")
	DIGIT = __ERDE_TMP_4__["DIGIT"]
	HEX = __ERDE_TMP_4__["HEX"]
	STANDARD_ESCAPE_CHARS = __ERDE_TMP_4__["STANDARD_ESCAPE_CHARS"]
	SYMBOLS = __ERDE_TMP_4__["SYMBOLS"]
	TOKEN_TYPES = __ERDE_TMP_4__["TOKEN_TYPES"]
	WORD_BODY = __ERDE_TMP_4__["WORD_BODY"]
	WORD_HEAD = __ERDE_TMP_4__["WORD_HEAD"]
end
local get_source_alias
do
	local __ERDE_TMP_7__
	__ERDE_TMP_7__ = require("erde.utils")
	get_source_alias = __ERDE_TMP_7__["get_source_alias"]
end
local tokenize_token
local tokens = {}
local text = ""
local current_char = ""
local current_char_index = 1
local current_line = 1
local source_name = ""
local function peek(n)
	return text:sub(current_char_index, current_char_index + n - 1)
end
local function look_ahead(n)
	return text:sub(current_char_index + n, current_char_index + n)
end
local function throw(message, line)
	if line == nil then
		line = current_line
	end
	error((tostring(source_name) .. ":" .. tostring(line) .. ": " .. tostring(message)), 0)
end
local function consume(n)
	if n == nil then
		n = 1
	end
	local consumed = n == 1 and current_char or peek(n)
	current_char_index = current_char_index + n
	current_char = text:sub(current_char_index, current_char_index)
	return consumed
end
local function newline()
	current_line = current_line + 1
	return consume()
end
local function tokenize_binary()
	consume(2)
	if current_char ~= "0" and current_char ~= "1" then
		throw("malformed binary")
	end
	local value = 0
	repeat
		value = 2 * value + tonumber(consume())
	until current_char ~= "0" and current_char ~= "1"
	table.insert(tokens, {
		type = TOKEN_TYPES.NUMBER,
		line = current_line,
		value = tostring(value),
	})
end
local function tokenize_decimal()
	local value = ""
	while DIGIT[current_char] do
		value = value .. consume()
	end
	if current_char == "." and DIGIT[look_ahead(1)] then
		value = value .. consume(2)
		while DIGIT[current_char] do
			value = value .. consume()
		end
	end
	if current_char == "e" or current_char == "E" then
		value = value .. consume()
		if current_char == "+" or current_char == "-" then
			value = value .. consume()
		end
		if not DIGIT[current_char] then
			throw("missing exponent value")
		end
		while DIGIT[current_char] do
			value = value .. consume()
		end
	end
	table.insert(tokens, {
		type = TOKEN_TYPES.NUMBER,
		line = current_line,
		value = value,
	})
end
local function tokenize_hex()
	consume(2)
	if not HEX[current_char] and not (current_char == "." and HEX[look_ahead(1)]) then
		throw("malformed hex")
	end
	local value = 0
	while HEX[current_char] do
		value = 16 * value + tonumber(consume(), 16)
	end
	if current_char == "." and HEX[look_ahead(1)] then
		consume()
		local counter = 1
		repeat
			value = value + tonumber(consume(), 16) / (16 ^ counter)
			counter = counter + 1
		until not HEX[current_char]
	end
	if current_char == "p" or current_char == "P" then
		consume()
		local exponent, sign = 0, 1
		if current_char == "+" or current_char == "-" then
			sign = sign * tonumber(consume() .. "1")
		end
		if not DIGIT[current_char] then
			throw("missing exponent value")
		end
		repeat
			exponent = 10 * exponent + tonumber(consume())
		until not DIGIT[current_char]
		value = value * 2 ^ (sign * exponent)
	end
	table.insert(tokens, {
		type = TOKEN_TYPES.NUMBER,
		line = current_line,
		value = tostring(value),
	})
end
local function escape_sequence()
	if STANDARD_ESCAPE_CHARS[current_char] then
		return consume()
	elseif DIGIT[current_char] then
		return consume()
	elseif current_char == "z" then
		if config.lua_target == "5.1" or config.lua_target == "5.1+" then
			throw("escape sequence \\z not compatible w/ lua targets 5.1, 5.1+")
		end
		return consume()
	elseif current_char == "x" then
		if config.lua_target == "5.1" or config.lua_target == "5.1+" then
			throw("escape sequence \\xXX not compatible w/ lua targets 5.1, 5.1+")
		end
		if not HEX[look_ahead(1)] or not HEX[look_ahead(2)] then
			throw("escape sequence \\xXX must use exactly 2 hex characters")
		end
		return consume(3)
	elseif current_char == "u" then
		if
			config.lua_target == "5.1"
			or config.lua_target == "5.1+"
			or config.lua_target == "5.2"
			or config.lua_target == "5.2+"
		then
			throw("escape sequence \\u{XXX} not compatible w/ lua targets 5.1, 5.1+, 5.2, 5.2+")
		end
		local sequence = consume()
		if current_char ~= "{" then
			throw("missing { in escape sequence \\u{XXX}")
		end
		sequence = sequence .. consume()
		if not HEX[current_char] then
			throw("missing hex in escape sequence \\u{XXX}")
		end
		while HEX[current_char] do
			sequence = sequence .. consume()
		end
		if current_char ~= "}" then
			throw("missing } in escape sequence \\u{XXX}")
		end
		return sequence .. consume()
	else
		throw(("invalid escape sequence \\" .. tostring(current_char)))
	end
end
local function tokenize_interpolation()
	table.insert(tokens, {
		type = TOKEN_TYPES.INTERPOLATION,
		line = current_line,
		value = consume(),
	})
	local interpolation_line = current_line
	local brace_depth = 0
	while current_char ~= "}" or brace_depth > 0 do
		if current_char == "{" then
			brace_depth = brace_depth + 1
			table.insert(tokens, {
				type = TOKEN_TYPES.SYMBOL,
				line = current_line,
				value = consume(),
			})
		elseif current_char == "}" then
			brace_depth = brace_depth - 1
			table.insert(tokens, {
				type = TOKEN_TYPES.SYMBOL,
				line = current_line,
				value = consume(),
			})
		elseif current_char == "" then
			throw("unterminated interpolation", interpolation_line)
		else
			tokenize_token()
		end
	end
	table.insert(tokens, {
		type = TOKEN_TYPES.INTERPOLATION,
		line = current_line,
		value = consume(),
	})
end
local function tokenize_single_quote_string()
	consume()
	local content = ""
	while current_char ~= "'" do
		if current_char == "" or current_char == "\n" then
			throw("unterminated string")
		elseif current_char == "\\" then
			content = content .. consume() .. escape_sequence()
		else
			content = content .. consume()
		end
	end
	consume()
	table.insert(tokens, {
		type = TOKEN_TYPES.SINGLE_QUOTE_STRING,
		line = current_line,
		value = content,
	})
end
local function tokenize_double_quote_string()
	table.insert(tokens, {
		type = TOKEN_TYPES.DOUBLE_QUOTE_STRING,
		line = current_line,
		value = consume(),
	})
	local content, content_line = "", current_line
	while current_char ~= '"' do
		if current_char == "" or current_char == "\n" then
			throw("unterminated string")
		elseif current_char == "\\" then
			consume()
			if current_char == "{" or current_char == "}" then
				content = content .. consume()
			else
				content = content .. "\\" .. escape_sequence()
			end
		elseif current_char == "{" then
			if content ~= "" then
				table.insert(tokens, {
					type = TOKEN_TYPES.STRING_CONTENT,
					line = content_line,
					value = content,
				})
				content, content_line = "", current_line
			end
			tokenize_interpolation()
		else
			content = content .. consume()
		end
	end
	if content ~= "" then
		table.insert(tokens, {
			type = TOKEN_TYPES.STRING_CONTENT,
			line = content_line,
			value = content,
		})
	end
	table.insert(tokens, {
		type = TOKEN_TYPES.DOUBLE_QUOTE_STRING,
		line = current_line,
		value = consume(),
	})
end
local function tokenize_block_string()
	consume()
	local equals = ""
	while current_char == "=" do
		equals = equals .. consume()
	end
	if current_char ~= "[" then
		throw("unterminated block string opening", current_line)
	end
	consume()
	table.insert(tokens, {
		type = TOKEN_TYPES.BLOCK_STRING,
		line = current_line,
		value = "[" .. equals .. "[",
	})
	local close_quote = "]" .. equals .. "]"
	local close_quote_len = #close_quote
	local block_string_line = current_line
	local content, content_line = "", current_line
	while current_char ~= "]" or peek(close_quote_len) ~= close_quote do
		if current_char == "" then
			throw("unterminated block string", block_string_line)
		elseif current_char == "\n" then
			content = content .. newline()
		elseif current_char == "\\" then
			consume()
			if current_char == "{" or current_char == "}" then
				content = content .. consume()
			else
				content = content .. "\\"
			end
		elseif current_char == "{" then
			if content ~= "" then
				table.insert(tokens, {
					type = TOKEN_TYPES.STRING_CONTENT,
					line = content_line,
					value = content,
				})
				content, content_line = "", current_line
			end
			tokenize_interpolation()
		else
			content = content .. consume()
		end
	end
	if content ~= "" then
		table.insert(tokens, {
			type = TOKEN_TYPES.STRING_CONTENT,
			line = content_line,
			value = content,
		})
	end
	table.insert(tokens, {
		type = TOKEN_TYPES.BLOCK_STRING,
		line = current_line,
		value = consume(close_quote_len),
	})
end
local function tokenize_word()
	local word = consume()
	while WORD_BODY[current_char] do
		word = word .. consume()
	end
	table.insert(tokens, {
		type = TOKEN_TYPES.WORD,
		line = current_line,
		value = word,
	})
end
local function tokenize_comment()
	consume(2)
	local is_block_comment, equals = false, ""
	if current_char == "[" then
		consume()
		while current_char == "=" do
			equals = equals .. consume()
		end
		if current_char == "[" then
			consume()
			is_block_comment = true
		end
	end
	if not is_block_comment then
		while current_char ~= "" and current_char ~= "\n" do
			consume()
		end
	else
		local close_quote = "]" .. equals .. "]"
		local close_quote_len = #close_quote
		local comment_line = current_line
		while current_char ~= "]" or peek(close_quote_len) ~= close_quote do
			if current_char == "" then
				throw("unterminated comment", comment_line)
			elseif current_char == "\n" then
				newline()
			else
				consume()
			end
		end
		consume(close_quote_len)
	end
end
function tokenize_token()
	if current_char == "\n" then
		newline()
	elseif current_char == " " or current_char == "\t" then
		consume()
	elseif WORD_HEAD[current_char] then
		tokenize_word()
	elseif current_char == "'" then
		tokenize_single_quote_string()
	elseif current_char == '"' then
		tokenize_double_quote_string()
	else
		local peek_two = peek(2)
		if peek_two == "--" then
			tokenize_comment()
		elseif peek_two == "0x" or peek_two == "0X" then
			tokenize_hex()
		elseif peek_two == "0b" or peek_two == "0B" then
			tokenize_binary()
		elseif DIGIT[current_char] or (current_char == "." and DIGIT[look_ahead(1)]) then
			tokenize_decimal()
		elseif peek_two == "[[" or peek_two == "[=" then
			tokenize_block_string()
		elseif SYMBOLS[peek(3)] then
			table.insert(tokens, {
				type = TOKEN_TYPES.SYMBOL,
				line = current_line,
				value = consume(3),
			})
		elseif SYMBOLS[peek_two] then
			table.insert(tokens, {
				type = TOKEN_TYPES.SYMBOL,
				line = current_line,
				value = consume(2),
			})
		else
			table.insert(tokens, {
				type = TOKEN_TYPES.SYMBOL,
				line = current_line,
				value = consume(1),
			})
		end
	end
end
return function(new_text, new_source_name)
	tokens = {}
	text = new_text
	current_char = text:sub(1, 1)
	current_char_index = 1
	current_line = 1
	source_name = new_source_name or get_source_alias(text)
	if peek(2) == "#!" then
		local shebang = consume(2)
		while current_char ~= "" and current_char ~= "\n" do
			shebang = shebang .. consume()
		end
		table.insert(tokens, {
			type = TOKEN_TYPES.SHEBANG,
			line = current_line,
			value = shebang,
		})
	end
	while current_char ~= "" do
		tokenize_token()
	end
	return tokens, current_line
end
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
