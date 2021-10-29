-- -----------------------------------------------------------------------------
-- Unops / Binops
-- -----------------------------------------------------------------------------

local LEFT_ASSOCIATIVE = -1
local RIGHT_ASSOCIATIVE = 1

local UNOPS = {
  { tag = 'neg', token = '-', prec = 14 },
  { tag = 'len', token = '#', prec = 14 },
  { tag = 'not', token = '~', prec = 14 },
  { tag = 'bnot', token = '.~', prec = 14 },
}

local UNOP_MAP = {}
for _, op in pairs(UNOPS) do
  UNOP_MAP[op.token] = op
end

local UNOP_MAX_LEN = 0
for _, op in pairs(UNOPS) do
  UNOP_MAX_LEN = math.max(UNOP_MAX_LEN, #op.token)
end

local BINOPS = {
  { tag = 'pipe', token = '>>', prec = 1, assoc = LEFT_ASSOCIATIVE },
  { tag = 'ternary', token = '?', prec = 2, assoc = LEFT_ASSOCIATIVE },
  { tag = 'nc', token = '??', prec = 3, assoc = LEFT_ASSOCIATIVE },
  { tag = 'or', token = '|', prec = 4, assoc = LEFT_ASSOCIATIVE },
  { tag = 'and', token = '&', prec = 5, assoc = LEFT_ASSOCIATIVE },
  { tag = 'eq', token = '==', prec = 6, assoc = LEFT_ASSOCIATIVE },
  { tag = 'neq', token = '~=', prec = 6, assoc = LEFT_ASSOCIATIVE },
  { tag = 'lte', token = '<=', prec = 6, assoc = LEFT_ASSOCIATIVE },
  { tag = 'gte', token = '>=', prec = 6, assoc = LEFT_ASSOCIATIVE },
  { tag = 'lt', token = '<', prec = 6, assoc = LEFT_ASSOCIATIVE },
  { tag = 'gt', token = '>', prec = 6, assoc = LEFT_ASSOCIATIVE },
  { tag = 'bor', token = '.|', prec = 7, assoc = LEFT_ASSOCIATIVE },
  { tag = 'bxor', token = '.~', prec = 8, assoc = LEFT_ASSOCIATIVE },
  { tag = 'band', token = '.&', prec = 9, assoc = LEFT_ASSOCIATIVE },
  { tag = 'lshift', token = '.<<', prec = 10, assoc = LEFT_ASSOCIATIVE },
  { tag = 'rshift', token = '.>>', prec = 10, assoc = LEFT_ASSOCIATIVE },
  { tag = 'concat', token = '..', prec = 11, assoc = LEFT_ASSOCIATIVE },
  { tag = 'add', token = '+', prec = 12, assoc = LEFT_ASSOCIATIVE },
  { tag = 'sub', token = '-', prec = 12, assoc = LEFT_ASSOCIATIVE },
  { tag = 'mult', token = '*', prec = 13, assoc = LEFT_ASSOCIATIVE },
  { tag = 'div', token = '/', prec = 13, assoc = LEFT_ASSOCIATIVE },
  { tag = 'intdiv', token = '//', prec = 13, assoc = LEFT_ASSOCIATIVE },
  { tag = 'mod', token = '%', prec = 13, assoc = LEFT_ASSOCIATIVE },
  { tag = 'exp', token = '^', prec = 15, assoc = RIGHT_ASSOCIATIVE },
}

local BINOP_MAP = {}
for _, op in pairs(BINOPS) do
  BINOP_MAP[op.token] = op
end

local BINOP_MAX_LEN = 0
for _, op in pairs(BINOPS) do
  BINOP_MAX_LEN = math.max(BINOP_MAX_LEN, #op.token)
end

-- -----------------------------------------------------------------------------
-- Return
-- TODO: use env here instead of copying over?
-- -----------------------------------------------------------------------------

return {
  EOF = -1,

  LEFT_ASSOCIATIVE = LEFT_ASSOCIATIVE,
  RIGHT_ASSOCIATIVE = RIGHT_ASSOCIATIVE,
  UNOPS = UNOPS,
  UNOP_MAP = UNOP_MAP,
  UNOP_MAX_LEN = UNOP_MAX_LEN,
  BINOPS = BINOPS,
  BINOP_MAP = BINOP_MAP,
  BINOP_MAX_LEN = BINOP_MAX_LEN,

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
    'self',
  },

  TERMINALS = {
    'true',
    'false',
    'nil',
    'self',
  },
}
