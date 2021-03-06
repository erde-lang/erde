local C = {}

-- Get the current platform path separator. Note that while this is undocumented
-- in the Lua 5.1 manual, it is indeed supported in 5.1+.
--
-- https://www.lua.org/manual/5.3/manual.html#pdf-package.config
C.PATH_SEPARATOR = package.config:sub(1, 1)

-- A header comment we inject into compiled code in order to track which files
-- have been generated by the cli (and thus allows us to also clean them later).
C.COMPILED_FOOTER_COMMENT = '-- __ERDE_COMPILED__'
C.COMPILED_FOOTER_COMMENT_LEN = #C.COMPILED_FOOTER_COMMENT

-- Flag to know whether or not we are running under the cli. Required for more
-- precise error rewriting.
C.IS_CLI_RUNTIME = false

-- -----------------------------------------------------------------------------
-- Keywords / Terminals
-- -----------------------------------------------------------------------------

C.KEYWORDS = {
  'local',
  'global',
  'module',
  'if',
  'elseif',
  'else',
  'for',
  'in',
  'while',
  'repeat',
  'until',
  'do',
  'function',
  'false',
  'true',
  'nil',
  'return',
  'try',
  'catch',
  'break',
  'continue',
}

C.TERMINALS = {
  'true',
  'false',
  'nil',
  '...',
}

-- -----------------------------------------------------------------------------
-- Unops / Binops
-- -----------------------------------------------------------------------------

C.LEFT_ASSOCIATIVE = -1
C.RIGHT_ASSOCIATIVE = 1

C.UNOPS = {
  ['-'] = { prec = 13 },
  ['#'] = { prec = 13 },
  ['!'] = { prec = 13 },
  ['~'] = { prec = 13 },
}

for opToken, op in pairs(C.UNOPS) do
  op.token = opToken
end

C.BINOPS = {
  ['||'] = { prec = 3, assoc = C.LEFT_ASSOCIATIVE },
  ['&&'] = { prec = 4, assoc = C.LEFT_ASSOCIATIVE },
  ['=='] = { prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['!='] = { prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['<='] = { prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['>='] = { prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['<'] = { prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['>'] = { prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['..'] = { prec = 10, assoc = C.LEFT_ASSOCIATIVE },
  ['+'] = { prec = 11, assoc = C.LEFT_ASSOCIATIVE },
  ['-'] = { prec = 11, assoc = C.LEFT_ASSOCIATIVE },
  ['*'] = { prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  ['/'] = { prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  ['%'] = { prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  ['^'] = { prec = 14, assoc = C.RIGHT_ASSOCIATIVE },
}

C.BITOPS = {
  ['|'] = { prec = 6, assoc = C.LEFT_ASSOCIATIVE },
  ['~'] = { prec = 7, assoc = C.LEFT_ASSOCIATIVE },
  ['&'] = { prec = 8, assoc = C.LEFT_ASSOCIATIVE },
  ['<<'] = { prec = 9, assoc = C.LEFT_ASSOCIATIVE },
  ['>>'] = { prec = 9, assoc = C.LEFT_ASSOCIATIVE },
}

for opToken, op in pairs(C.BITOPS) do
  C.BINOPS[opToken] = op
end

for opToken, op in pairs(C.BINOPS) do
  op.token = opToken
end

-- These operators cannot be used w/ operator assignment
C.BINOP_ASSIGNMENT_BLACKLIST = {
  ['=='] = true,
  ['~='] = true,
  ['<='] = true,
  ['>='] = true,
  ['<'] = true,
  ['>'] = true,
}

-- -----------------------------------------------------------------------------
-- Lookup Tables
-- -----------------------------------------------------------------------------

C.SYMBOLS = {
  ['->'] = true,
  ['=>'] = true,
  ['...'] = true,
  ['::'] = true,
}

for opToken, op in pairs(C.BINOPS) do
  if #opToken > 1 then
    C.SYMBOLS[opToken] = true
  end
end

C.ALPHA = {}
C.DIGIT = {}
C.HEX = {}
C.WORD_HEAD = { ['_'] = true }
C.WORD_BODY = { ['_'] = true }

for byte = string.byte('0'), string.byte('9') do
  local char = string.char(byte)
  C.DIGIT[char] = true
  C.HEX[char] = true
  C.WORD_BODY[char] = true
end

for byte = string.byte('A'), string.byte('F') do
  local char = string.char(byte)
  C.ALPHA[char] = true
  C.HEX[char] = true
  C.WORD_HEAD[char] = true
  C.WORD_BODY[char] = true
end

for byte = string.byte('G'), string.byte('Z') do
  local char = string.char(byte)
  C.ALPHA[char] = true
  C.WORD_HEAD[char] = true
  C.WORD_BODY[char] = true
end

for byte = string.byte('a'), string.byte('f') do
  local char = string.char(byte)
  C.ALPHA[char] = true
  C.HEX[char] = true
  C.WORD_HEAD[char] = true
  C.WORD_BODY[char] = true
end

for byte = string.byte('g'), string.byte('z') do
  local char = string.char(byte)
  C.ALPHA[char] = true
  C.WORD_HEAD[char] = true
  C.WORD_BODY[char] = true
end

-- -----------------------------------------------------------------------------
-- Lua Target
-- -----------------------------------------------------------------------------

C.LUA_TARGET = '5.1+'

C.VALID_LUA_TARGETS = {
  'JIT',
  '5.1',
  '5.1+',
  '5.2',
  '5.2+',
  '5.3',
  '5.3+',
  '5.4',
  '5.4+',
}

for i, target in ipairs(C.VALID_LUA_TARGETS) do
  C.VALID_LUA_TARGETS[target] = true
end

-- Compiling bit operations for these targets are dangerous, since Mike Pall's
-- LuaBitOp only works on 5.1 + 5.2, bit32 only works on 5.2, and 5.3 + 5.4 have
-- built-in bit operator support.
--
-- TODO: do not disallow bit operators for these targets if a custom bit lib is
-- set in the CLI
C.INVALID_BITOP_LUA_TARGETS = {
  ['5.1+'] = true,
  ['5.2+'] = true,
}

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return C
