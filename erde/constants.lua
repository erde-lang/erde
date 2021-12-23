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
  { tag = 'neg', token = '-', prec = 13 },
  { tag = 'len', token = '#', prec = 13 },
  { tag = 'not', token = '~', prec = 13 },
  { tag = 'bnot', token = '.~', prec = 13 },
}

C.UNOP_MAP = {}
for _, op in pairs(C.UNOPS) do
  C.UNOP_MAP[op.token] = op
end

C.UNOP_MAX_LEN = 0
for _, op in pairs(C.UNOPS) do
  C.UNOP_MAX_LEN = math.max(C.UNOP_MAX_LEN, #op.token)
end

C.BINOPS = {
  { tag = 'ternary', token = '?', prec = 1, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'nc', token = '??', prec = 2, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'or', token = '|', prec = 3, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'and', token = '&', prec = 4, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'eq', token = '==', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'neq', token = '~=', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'lte', token = '<=', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'gte', token = '>=', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'lt', token = '<', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'gt', token = '>', prec = 5, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'bor', token = '.|', prec = 6, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'bxor', token = '.~', prec = 7, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'band', token = '.&', prec = 8, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'lshift', token = '.<<', prec = 9, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'rshift', token = '.>>', prec = 9, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'concat', token = '..', prec = 10, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'add', token = '+', prec = 11, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'sub', token = '-', prec = 11, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'mult', token = '*', prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'div', token = '/', prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'intdiv', token = '//', prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'mod', token = '%', prec = 12, assoc = C.LEFT_ASSOCIATIVE },
  { tag = 'exp', token = '^', prec = 14, assoc = C.RIGHT_ASSOCIATIVE },
}

C.BINOP_MAP = {}
for _, op in pairs(C.BINOPS) do
  C.BINOP_MAP[op.token] = op
end

C.BINOP_MAX_LEN = 0
for _, op in pairs(C.BINOPS) do
  C.BINOP_MAX_LEN = math.max(C.BINOP_MAX_LEN, #op.token)
end

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
