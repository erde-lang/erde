local CC = {}

-- -----------------------------------------------------------------------------
-- Keywords / Terminals
-- -----------------------------------------------------------------------------

CC.KEYWORDS = {
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
  'break',
  'continue',
}

-- Words that are keywords in Lua but NOT in Erde.
CC.LUA_KEYWORDS = {
  ['not'] = true,
  ['and'] = true,
  ['or'] = true,
  ['end'] = true,
  ['then'] = true,
}

CC.TERMINALS = {
  'true',
  'false',
  'nil',
  '...',
}

-- -----------------------------------------------------------------------------
-- Operations
-- -----------------------------------------------------------------------------

CC.LEFT_ASSOCIATIVE = -1
CC.RIGHT_ASSOCIATIVE = 1

CC.UNOPS = {
  ['-'] = { prec = 13 },
  ['#'] = { prec = 13 },
  ['!'] = { prec = 13 },
  ['~'] = { prec = 13 },
}

for token, op in pairs(CC.UNOPS) do
  op.token = token
end

CC.BITOPS = {
  ['|'] = { prec = 6, assoc = CC.LEFT_ASSOCIATIVE },
  ['~'] = { prec = 7, assoc = CC.LEFT_ASSOCIATIVE },
  ['&'] = { prec = 8, assoc = CC.LEFT_ASSOCIATIVE },
  ['<<'] = { prec = 9, assoc = CC.LEFT_ASSOCIATIVE },
  ['>>'] = { prec = 9, assoc = CC.LEFT_ASSOCIATIVE },
}

CC.BITLIB_METHODS = {
  ['|'] = 'bor',
  ['~'] = 'bxor',
  ['&'] = 'band',
  ['<<'] = 'lshift',
  ['>>'] = 'rshift',
}

CC.BINOPS = {
  ['||'] = { prec = 3, assoc = CC.LEFT_ASSOCIATIVE },
  ['&&'] = { prec = 4, assoc = CC.LEFT_ASSOCIATIVE },
  ['=='] = { prec = 5, assoc = CC.LEFT_ASSOCIATIVE },
  ['!='] = { prec = 5, assoc = CC.LEFT_ASSOCIATIVE },
  ['<='] = { prec = 5, assoc = CC.LEFT_ASSOCIATIVE },
  ['>='] = { prec = 5, assoc = CC.LEFT_ASSOCIATIVE },
  ['<'] = { prec = 5, assoc = CC.LEFT_ASSOCIATIVE },
  ['>'] = { prec = 5, assoc = CC.LEFT_ASSOCIATIVE },
  ['..'] = { prec = 10, assoc = CC.LEFT_ASSOCIATIVE },
  ['+'] = { prec = 11, assoc = CC.LEFT_ASSOCIATIVE },
  ['-'] = { prec = 11, assoc = CC.LEFT_ASSOCIATIVE },
  ['*'] = { prec = 12, assoc = CC.LEFT_ASSOCIATIVE },
  ['/'] = { prec = 12, assoc = CC.LEFT_ASSOCIATIVE },
  ['//'] = { prec = 12, assoc = CC.LEFT_ASSOCIATIVE },
  ['%'] = { prec = 12, assoc = CC.LEFT_ASSOCIATIVE },
  ['^'] = { prec = 14, assoc = CC.RIGHT_ASSOCIATIVE },
}

for token, op in pairs(CC.BITOPS) do
  CC.BINOPS[token] = op
end

for token, op in pairs(CC.BINOPS) do
  op.token = token
end

CC.BINOP_ASSIGNMENT_TOKENS = {
  ['||'] = true,
  ['&&'] = true,
  ['..'] = true,
  ['+'] = true,
  ['-'] = true,
  ['*'] = true,
  ['/'] = true,
  ['//'] = true,
  ['%'] = true,
  ['^'] = true,
  ['|'] = true,
  ['~'] = true,
  ['&'] = true,
  ['<<'] = true,
  ['>>'] = true,
}

-- -----------------------------------------------------------------------------
-- Lookup Tables
-- -----------------------------------------------------------------------------

CC.SURROUND_ENDS = {
  ['('] = ')',
  ['['] = ']',
  ['{'] = '}',
}

CC.SYMBOLS = {
  ['->'] = true,
  ['=>'] = true,
  ['...'] = true,
  ['::'] = true,
}

for token, op in pairs(CC.BINOPS) do
  if #token > 1 then
    CC.SYMBOLS[token] = true
  end
end

-- Valid escape characters for 5.1+
CC.STANDARD_ESCAPE_CHARS = {
  a = true,
  b = true,
  f = true,
  n = true,
  r = true,
  t = true,
  v = true,
  ['\\'] = true,
  ['"'] = true,
  ["'"] = true,
  ['\n'] = true,
}

CC.DIGIT = {}
CC.HEX = {}
CC.WORD_HEAD = { ['_'] = true }
CC.WORD_BODY = { ['_'] = true }

for byte = string.byte('0'), string.byte('9') do
  local char = string.char(byte)
  CC.DIGIT[char] = true
  CC.HEX[char] = true
  CC.WORD_BODY[char] = true
end

for byte = string.byte('A'), string.byte('F') do
  local char = string.char(byte)
  CC.HEX[char] = true
  CC.WORD_HEAD[char] = true
  CC.WORD_BODY[char] = true
end

for byte = string.byte('G'), string.byte('Z') do
  local char = string.char(byte)
  CC.WORD_HEAD[char] = true
  CC.WORD_BODY[char] = true
end

for byte = string.byte('a'), string.byte('f') do
  local char = string.char(byte)
  CC.HEX[char] = true
  CC.WORD_HEAD[char] = true
  CC.WORD_BODY[char] = true
end

for byte = string.byte('g'), string.byte('z') do
  local char = string.char(byte)
  CC.WORD_HEAD[char] = true
  CC.WORD_BODY[char] = true
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return CC
