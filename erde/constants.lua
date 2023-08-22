local _MODULE = {}
_MODULE.VERSION = "1.0.0-1"
_MODULE.PATH_SEPARATOR = package.config:sub(1, 1)
_MODULE.COMPILED_FOOTER_COMMENT = "-- __ERDE_COMPILED__"
_MODULE.TOKEN_TYPES = {
	EOF = 0,
	SHEBANG = 1,
	SYMBOL = 2,
	WORD = 3,
	NUMBER = 4,
	SINGLE_QUOTE_STRING = 5,
	DOUBLE_QUOTE_STRING = 6,
	STRING_CONTENT = 7,
	INTERPOLATION = 8,
}
_MODULE.VALID_LUA_TARGETS = {
	"jit",
	"5.1",
	"5.1+",
	"5.2",
	"5.2+",
	"5.3",
	"5.3+",
	"5.4",
	"5.4+",
}
for i, target in ipairs(_MODULE.VALID_LUA_TARGETS) do
	_MODULE.VALID_LUA_TARGETS[target] = true
end
_MODULE.KEYWORDS = {
	["break"] = true,
	["continue"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["for"] = true,
	["function"] = true,
	["global"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["module"] = true,
	["repeat"] = true,
	["return"] = true,
	["until"] = true,
	["while"] = true,
}
_MODULE.LUA_KEYWORDS = {
	["not"] = true,
	["and"] = true,
	["or"] = true,
	["end"] = true,
	["then"] = true,
}
_MODULE.TERMINALS = {
	["true"] = true,
	["false"] = true,
	["nil"] = true,
	["..."] = true,
}
_MODULE.LEFT_ASSOCIATIVE = -1
_MODULE.RIGHT_ASSOCIATIVE = 1
_MODULE.UNOPS = {
	["-"] = {
		prec = 13,
	},
	["#"] = {
		prec = 13,
	},
	["!"] = {
		prec = 13,
	},
	["~"] = {
		prec = 13,
	},
}
for token, op in pairs(_MODULE.UNOPS) do
	op.token = token
end
_MODULE.BITOPS = {
	["|"] = {
		prec = 6,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["~"] = {
		prec = 7,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["&"] = {
		prec = 8,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["<<"] = {
		prec = 9,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	[">>"] = {
		prec = 9,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
}
_MODULE.BITLIB_METHODS = {
	["|"] = "bor",
	["~"] = "bxor",
	["&"] = "band",
	["<<"] = "lshift",
	[">>"] = "rshift",
}
_MODULE.BINOPS = {
	["||"] = {
		prec = 3,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["&&"] = {
		prec = 4,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["=="] = {
		prec = 5,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["!="] = {
		prec = 5,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["<="] = {
		prec = 5,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	[">="] = {
		prec = 5,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["<"] = {
		prec = 5,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	[">"] = {
		prec = 5,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	[".."] = {
		prec = 10,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["+"] = {
		prec = 11,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["-"] = {
		prec = 11,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["*"] = {
		prec = 12,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["/"] = {
		prec = 12,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["//"] = {
		prec = 12,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["%"] = {
		prec = 12,
		assoc = _MODULE.LEFT_ASSOCIATIVE,
	},
	["^"] = {
		prec = 14,
		assoc = _MODULE.RIGHT_ASSOCIATIVE,
	},
}
for token, op in pairs(_MODULE.BITOPS) do
	_MODULE.BINOPS[token] = op
end
for token, op in pairs(_MODULE.BINOPS) do
	op.token = token
end
_MODULE.BINOP_ASSIGNMENT_TOKENS = {
	["||"] = true,
	["&&"] = true,
	[".."] = true,
	["+"] = true,
	["-"] = true,
	["*"] = true,
	["/"] = true,
	["//"] = true,
	["%"] = true,
	["^"] = true,
	["|"] = true,
	["~"] = true,
	["&"] = true,
	["<<"] = true,
	[">>"] = true,
}
_MODULE.SURROUND_ENDS = {
	["("] = ")",
	["["] = "]",
	["{"] = "}",
}
_MODULE.SYMBOLS = {
	["->"] = true,
	["=>"] = true,
	["..."] = true,
	["::"] = true,
}
for token, op in pairs(_MODULE.BINOPS) do
	if #token > 1 then
		_MODULE.SYMBOLS[token] = true
	end
end
_MODULE.STANDARD_ESCAPE_CHARS = {
	a = true,
	b = true,
	f = true,
	n = true,
	r = true,
	t = true,
	v = true,
	["\\"] = true,
	['"'] = true,
	["'"] = true,
	["\n"] = true,
}
_MODULE.DIGIT = {}
_MODULE.HEX = {}
_MODULE.WORD_HEAD = {
	["_"] = true,
}
_MODULE.WORD_BODY = {
	["_"] = true,
}
for byte = string.byte("0"), string.byte("9") do
	local char = string.char(byte)
	_MODULE.DIGIT[char] = true
	_MODULE.HEX[char] = true
	_MODULE.WORD_BODY[char] = true
end
for byte = string.byte("A"), string.byte("F") do
	local char = string.char(byte)
	_MODULE.HEX[char] = true
	_MODULE.WORD_HEAD[char] = true
	_MODULE.WORD_BODY[char] = true
end
for byte = string.byte("G"), string.byte("Z") do
	local char = string.char(byte)
	_MODULE.WORD_HEAD[char] = true
	_MODULE.WORD_BODY[char] = true
end
for byte = string.byte("a"), string.byte("f") do
	local char = string.char(byte)
	_MODULE.HEX[char] = true
	_MODULE.WORD_HEAD[char] = true
	_MODULE.WORD_BODY[char] = true
end
for byte = string.byte("g"), string.byte("z") do
	local char = string.char(byte)
	_MODULE.WORD_HEAD[char] = true
	_MODULE.WORD_BODY[char] = true
end
return _MODULE
-- Compiled with Erde 1.0.0-1 w/ Lua target 5.1+
-- __ERDE_COMPILED__
