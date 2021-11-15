local Environment = require('erde.Environment')

-- -----------------------------------------------------------------------------
-- Environment
-- -----------------------------------------------------------------------------

local env = Environment()
env:addReference(_G)
local _ENV = env:load()

-- -----------------------------------------------------------------------------
-- Keywords / Terminals
-- -----------------------------------------------------------------------------

KEYWORDS = {
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

TERMINALS = {
  'true',
  'false',
  'nil',
}

-- -----------------------------------------------------------------------------
-- Unops / Binops
-- -----------------------------------------------------------------------------

LEFT_ASSOCIATIVE = -1
RIGHT_ASSOCIATIVE = 1

OP_BLACKLIST = {
  '>>',
}

UNOPS = {
  { tag = 'neg', token = '-', prec = 13 },
  { tag = 'len', token = '#', prec = 13 },
  { tag = 'not', token = '~', prec = 13 },
  { tag = 'bnot', token = '.~', prec = 13 },
}

UNOP_MAP = {}
for _, op in pairs(UNOPS) do
  UNOP_MAP[op.token] = op
end

UNOP_MAX_LEN = 0
for _, op in pairs(UNOPS) do
  UNOP_MAX_LEN = math.max(UNOP_MAX_LEN, #op.token)
end

BINOPS = {
  { tag = 'ternary', token = '?', prec = 1, assoc = LEFT_ASSOCIATIVE },
  { tag = 'nc', token = '??', prec = 2, assoc = LEFT_ASSOCIATIVE },
  { tag = 'or', token = '|', prec = 3, assoc = LEFT_ASSOCIATIVE },
  { tag = 'and', token = '&', prec = 4, assoc = LEFT_ASSOCIATIVE },
  { tag = 'eq', token = '==', prec = 5, assoc = LEFT_ASSOCIATIVE },
  { tag = 'neq', token = '~=', prec = 5, assoc = LEFT_ASSOCIATIVE },
  { tag = 'lte', token = '<=', prec = 5, assoc = LEFT_ASSOCIATIVE },
  { tag = 'gte', token = '>=', prec = 5, assoc = LEFT_ASSOCIATIVE },
  { tag = 'lt', token = '<', prec = 5, assoc = LEFT_ASSOCIATIVE },
  { tag = 'gt', token = '>', prec = 5, assoc = LEFT_ASSOCIATIVE },
  { tag = 'bor', token = '.|', prec = 6, assoc = LEFT_ASSOCIATIVE },
  { tag = 'bxor', token = '.~', prec = 7, assoc = LEFT_ASSOCIATIVE },
  { tag = 'band', token = '.&', prec = 8, assoc = LEFT_ASSOCIATIVE },
  { tag = 'lshift', token = '.<<', prec = 9, assoc = LEFT_ASSOCIATIVE },
  { tag = 'rshift', token = '.>>', prec = 9, assoc = LEFT_ASSOCIATIVE },
  { tag = 'concat', token = '..', prec = 10, assoc = LEFT_ASSOCIATIVE },
  { tag = 'add', token = '+', prec = 11, assoc = LEFT_ASSOCIATIVE },
  { tag = 'sub', token = '-', prec = 11, assoc = LEFT_ASSOCIATIVE },
  { tag = 'mult', token = '*', prec = 12, assoc = LEFT_ASSOCIATIVE },
  { tag = 'div', token = '/', prec = 12, assoc = LEFT_ASSOCIATIVE },
  { tag = 'intdiv', token = '//', prec = 12, assoc = LEFT_ASSOCIATIVE },
  { tag = 'mod', token = '%', prec = 12, assoc = LEFT_ASSOCIATIVE },
  { tag = 'exp', token = '^', prec = 14, assoc = RIGHT_ASSOCIATIVE },
}

BINOP_MAP = {}
for _, op in pairs(BINOPS) do
  BINOP_MAP[op.token] = op
end

BINOP_MAX_LEN = 0
for _, op in pairs(BINOPS) do
  BINOP_MAX_LEN = math.max(BINOP_MAX_LEN, #op.token)
end

-- -----------------------------------------------------------------------------
-- Lookup Tables
-- -----------------------------------------------------------------------------

UPPERCASE = {}
ALPHA = {}
DIGIT = {}
ALNUM = {}
HEX = {}
WHITESPACE = {
  ['\n'] = true,
  ['\t'] = true,
  [' '] = true,
}

for byte = string.byte('0'), string.byte('9') do
  local char = string.char(byte)
  DIGIT[char] = true
  ALNUM[char] = true
  HEX[char] = true
end
for byte = string.byte('A'), string.byte('F') do
  local char = string.char(byte)
  ALPHA[char] = true
  ALNUM[char] = true
  HEX[char] = true
  UPPERCASE[char] = true
end
for byte = string.byte('G'), string.byte('Z') do
  local char = string.char(byte)
  ALPHA[char] = true
  ALNUM[char] = true
  UPPERCASE[char] = true
end
for byte = string.byte('a'), string.byte('f') do
  local char = string.char(byte)
  ALPHA[char] = true
  ALNUM[char] = true
  HEX[char] = true
end
for byte = string.byte('g'), string.byte('z') do
  local char = string.char(byte)
  ALPHA[char] = true
  ALNUM[char] = true
end

-- -----------------------------------------------------------------------------
-- Misc
-- -----------------------------------------------------------------------------

EOF = -1

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return _ENV
