local _MODULE = {}
local VERSION = "0.6.0-1"
_MODULE.VERSION = VERSION
local PATH_SEPARATOR = package.config:sub(1, 1)
_MODULE.PATH_SEPARATOR = PATH_SEPARATOR
local COMPILED_FOOTER_COMMENT = "-- __ERDE_COMPILED__"
_MODULE.COMPILED_FOOTER_COMMENT = COMPILED_FOOTER_COMMENT
local IS_CLI_RUNTIME = false
_MODULE.IS_CLI_RUNTIME = IS_CLI_RUNTIME
local BITLIB = nil
_MODULE.BITLIB = BITLIB
local DISABLE_SOURCE_MAPS = false
_MODULE.DISABLE_SOURCE_MAPS = DISABLE_SOURCE_MAPS
local LUA_TARGET = "5.1+"
_MODULE.LUA_TARGET = LUA_TARGET
local VALID_LUA_TARGETS = {
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
_MODULE.VALID_LUA_TARGETS = VALID_LUA_TARGETS
for i, target in ipairs(VALID_LUA_TARGETS) do
	VALID_LUA_TARGETS[target] = true
end
local KEYWORDS = {
	"local",
	"global",
	"module",
	"if",
	"elseif",
	"else",
	"for",
	"in",
	"while",
	"repeat",
	"until",
	"do",
	"function",
	"false",
	"true",
	"nil",
	"return",
	"break",
	"continue",
}
_MODULE.KEYWORDS = KEYWORDS
local LUA_KEYWORDS = {
	["not"] = true,
	["and"] = true,
	["or"] = true,
	["end"] = true,
	["then"] = true,
}
_MODULE.LUA_KEYWORDS = LUA_KEYWORDS
local TERMINALS = {
	"true",
	"false",
	"nil",
	"...",
}
_MODULE.TERMINALS = TERMINALS
local LEFT_ASSOCIATIVE = -1
_MODULE.LEFT_ASSOCIATIVE = LEFT_ASSOCIATIVE
local RIGHT_ASSOCIATIVE = 1
_MODULE.RIGHT_ASSOCIATIVE = RIGHT_ASSOCIATIVE
local UNOPS = {
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
_MODULE.UNOPS = UNOPS
for token, op in pairs(UNOPS) do
	op.token = token
end
local BITOPS = {
	["|"] = {
		prec = 6,
		assoc = LEFT_ASSOCIATIVE,
	},
	["~"] = {
		prec = 7,
		assoc = LEFT_ASSOCIATIVE,
	},
	["&"] = {
		prec = 8,
		assoc = LEFT_ASSOCIATIVE,
	},
	["<<"] = {
		prec = 9,
		assoc = LEFT_ASSOCIATIVE,
	},
	[">>"] = {
		prec = 9,
		assoc = LEFT_ASSOCIATIVE,
	},
}
_MODULE.BITOPS = BITOPS
local BITLIB_METHODS = {
	["|"] = "bor",
	["~"] = "bxor",
	["&"] = "band",
	["<<"] = "lshift",
	[">>"] = "rshift",
}
_MODULE.BITLIB_METHODS = BITLIB_METHODS
local BINOPS = {
	["||"] = {
		prec = 3,
		assoc = LEFT_ASSOCIATIVE,
	},
	["&&"] = {
		prec = 4,
		assoc = LEFT_ASSOCIATIVE,
	},
	["=="] = {
		prec = 5,
		assoc = LEFT_ASSOCIATIVE,
	},
	["!="] = {
		prec = 5,
		assoc = LEFT_ASSOCIATIVE,
	},
	["<="] = {
		prec = 5,
		assoc = LEFT_ASSOCIATIVE,
	},
	[">="] = {
		prec = 5,
		assoc = LEFT_ASSOCIATIVE,
	},
	["<"] = {
		prec = 5,
		assoc = LEFT_ASSOCIATIVE,
	},
	[">"] = {
		prec = 5,
		assoc = LEFT_ASSOCIATIVE,
	},
	[".."] = {
		prec = 10,
		assoc = LEFT_ASSOCIATIVE,
	},
	["+"] = {
		prec = 11,
		assoc = LEFT_ASSOCIATIVE,
	},
	["-"] = {
		prec = 11,
		assoc = LEFT_ASSOCIATIVE,
	},
	["*"] = {
		prec = 12,
		assoc = LEFT_ASSOCIATIVE,
	},
	["/"] = {
		prec = 12,
		assoc = LEFT_ASSOCIATIVE,
	},
	["//"] = {
		prec = 12,
		assoc = LEFT_ASSOCIATIVE,
	},
	["%"] = {
		prec = 12,
		assoc = LEFT_ASSOCIATIVE,
	},
	["^"] = {
		prec = 14,
		assoc = RIGHT_ASSOCIATIVE,
	},
}
_MODULE.BINOPS = BINOPS
for token, op in pairs(BITOPS) do
	BINOPS[token] = op
end
for token, op in pairs(BINOPS) do
	op.token = token
end
local BINOP_ASSIGNMENT_TOKENS = {
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
_MODULE.BINOP_ASSIGNMENT_TOKENS = BINOP_ASSIGNMENT_TOKENS
local SURROUND_ENDS = {
	["("] = ")",
	["["] = "]",
	["{"] = "}",
}
_MODULE.SURROUND_ENDS = SURROUND_ENDS
local SYMBOLS = {
	["->"] = true,
	["=>"] = true,
	["..."] = true,
	["::"] = true,
}
_MODULE.SYMBOLS = SYMBOLS
for token, op in pairs(BINOPS) do
	if #token > 1 then
		SYMBOLS[token] = true
	end
end
local STANDARD_ESCAPE_CHARS = {
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
_MODULE.STANDARD_ESCAPE_CHARS = STANDARD_ESCAPE_CHARS
local DIGIT = {}
_MODULE.DIGIT = DIGIT
local HEX = {}
_MODULE.HEX = HEX
local WORD_HEAD = {
	["_"] = true,
}
_MODULE.WORD_HEAD = WORD_HEAD
local WORD_BODY = {
	["_"] = true,
}
_MODULE.WORD_BODY = WORD_BODY
for byte = string.byte("0"), string.byte("9") do
	local char = string.char(byte)
	DIGIT[char] = true
	HEX[char] = true
	WORD_BODY[char] = true
end
for byte = string.byte("A"), string.byte("F") do
	local char = string.char(byte)
	HEX[char] = true
	WORD_HEAD[char] = true
	WORD_BODY[char] = true
end
for byte = string.byte("G"), string.byte("Z") do
	local char = string.char(byte)
	WORD_HEAD[char] = true
	WORD_BODY[char] = true
end
for byte = string.byte("a"), string.byte("f") do
	local char = string.char(byte)
	HEX[char] = true
	WORD_HEAD[char] = true
	WORD_BODY[char] = true
end
for byte = string.byte("g"), string.byte("z") do
	local char = string.char(byte)
	WORD_HEAD[char] = true
	WORD_BODY[char] = true
end
return _MODULE
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
