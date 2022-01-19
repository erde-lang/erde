local C = {}

-- -----------------------------------------------------------------------------
-- Keywords / Terminals
-- -----------------------------------------------------------------------------

C.KEYWORDS = {
  'local',
  'global',
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

C.OP_BLACKLIST = {
  '>>', -- Custom rule for pipes
  '--', -- Do not parse comments as substraction!
}

C.UNOPS = {
  ['-'] = { tag = 'neg', prec = 13 },
  ['#'] = { tag = 'len', prec = 13 },
  ['~'] = { tag = 'not', prec = 13 },
  ['.~'] = { tag = 'bnot', prec = 13 },
}

C.BINOPS = {
  ['?'] = { tag = 'ternary', prec = 1, assoc = C.LEFT_ASSOCIATIVE },
  ['??'] = { tag = 'nc', prec = 2, assoc = C.LEFT_ASSOCIATIVE },
  ['|'] = { tag = 'or', prec = 3, assoc = C.LEFT_ASSOCIATIVE },
  ['&'] = { tag = 'and', prec = 4, assoc = C.LEFT_ASSOCIATIVE },
  ['=='] = { tag = 'eq', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['~='] = { tag = 'neq', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['<='] = { tag = 'lte', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['>='] = { tag = 'gte', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['<'] = { tag = 'lt', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['>'] = { tag = 'gt', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  ['.|'] = { tag = 'bor', prec = 6, assoc = C.LEFT_ASSOCIATIVE },
  ['.~'] = { tag = 'bxor', prec = 7, assoc = C.LEFT_ASSOCIATIVE },
  ['.&'] = { tag = 'band', prec = 8, assoc = C.LEFT_ASSOCIATIVE },
  ['.<<'] = { tag = 'lshift', prec = 9, assoc = C.LEFT_ASSOCIATIVE },
  ['.>>'] = { tag = 'rshift', prec = 9, assoc = C.LEFT_ASSOCIATIVE },
  ['..'] = { tag = 'concat', prec = 10, assoc = C.LEFT_ASSOCIATIVE },
  ['+'] = { tag = 'add', prec = 11, assoc = C.LEFT_ASSOCIATIVE },
  ['-'] = { tag = 'sub', prec = 11, assoc = C.LEFT_ASSOCIATIVE },
  ['*'] = { tag = 'mult', prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  ['/'] = { tag = 'div', prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  ['//'] = { tag = 'intdiv', prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  ['%'] = { tag = 'mod', prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  ['^'] = { tag = 'exp', prec = 14, assoc = C.RIGHT_ASSOCIATIVE },
}

-- -----------------------------------------------------------------------------
-- Lookup Tables
-- -----------------------------------------------------------------------------

C.UPPERCASE = {}
C.ALPHA = {}
C.DIGIT = {}
C.ALNUM = {}
C.HEX = {}
C.WHITESPACE = {
  ['\n'] = true,
  ['\t'] = true,
  [' '] = true,
}

for byte = string.byte('0'), string.byte('9') do
  local char = string.char(byte)
  C.DIGIT[char] = true
  C.ALNUM[char] = true
  C.HEX[char] = true
end
for byte = string.byte('A'), string.byte('F') do
  local char = string.char(byte)
  C.ALPHA[char] = true
  C.ALNUM[char] = true
  C.HEX[char] = true
  C.UPPERCASE[char] = true
end
for byte = string.byte('G'), string.byte('Z') do
  local char = string.char(byte)
  C.ALPHA[char] = true
  C.ALNUM[char] = true
  C.UPPERCASE[char] = true
end
for byte = string.byte('a'), string.byte('f') do
  local char = string.char(byte)
  C.ALPHA[char] = true
  C.ALNUM[char] = true
  C.HEX[char] = true
end
for byte = string.byte('g'), string.byte('z') do
  local char = string.char(byte)
  C.ALPHA[char] = true
  C.ALNUM[char] = true
end

-- -----------------------------------------------------------------------------
-- Misc
-- -----------------------------------------------------------------------------

C.EOF = -1

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return C
