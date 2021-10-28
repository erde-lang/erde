-- -----------------------------------------------------------------------------
-- Unops / Binops
-- -----------------------------------------------------------------------------

local LEFT_ASSOCIATIVE = -1
local RIGHT_ASSOCIATIVE = 1

local UNOPS = {
  ['-'] = { tag = 'neg', prec = 14 },
  ['#'] = { tag = 'len', prec = 14 },
  ['~'] = { tag = 'not', prec = 14 },
  ['.~'] = { tag = 'bnot', prec = 14 },
}

local BINOPS = {
  ['>>'] = { tag = 'pipe', prec = 1, assoc = LEFT_ASSOCIATIVE },
  ['?'] = { tag = 'ternary', prec = 2, assoc = LEFT_ASSOCIATIVE },
  ['??'] = { tag = 'nc', prec = 3, assoc = LEFT_ASSOCIATIVE },
  ['|'] = { tag = 'or', prec = 4, assoc = LEFT_ASSOCIATIVE },
  ['&'] = { tag = 'and', prec = 5, assoc = LEFT_ASSOCIATIVE },
  ['=='] = { tag = 'eq', prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['~='] = { tag = 'neq', prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['<='] = { tag = 'lte', prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['>='] = { tag = 'gte', prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['<'] = { tag = 'lt', prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['>'] = { tag = 'gt', prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['.|'] = { tag = 'bor', prec = 7, assoc = LEFT_ASSOCIATIVE },
  ['.~'] = { tag = 'bxor', prec = 8, assoc = LEFT_ASSOCIATIVE },
  ['.&'] = { tag = 'band', prec = 9, assoc = LEFT_ASSOCIATIVE },
  ['.<<'] = { tag = 'lshift', prec = 10, assoc = LEFT_ASSOCIATIVE },
  ['.>>'] = { tag = 'rshift', prec = 10, assoc = LEFT_ASSOCIATIVE },
  ['..'] = { tag = 'concat', prec = 11, assoc = LEFT_ASSOCIATIVE },
  ['+'] = { tag = 'add', prec = 12, assoc = LEFT_ASSOCIATIVE },
  ['-'] = { tag = 'sub', prec = 12, assoc = LEFT_ASSOCIATIVE },
  ['*'] = { tag = 'mult', prec = 13, assoc = LEFT_ASSOCIATIVE },
  ['/'] = { tag = 'div', prec = 13, assoc = LEFT_ASSOCIATIVE },
  ['//'] = { tag = 'intdiv', prec = 13, assoc = LEFT_ASSOCIATIVE },
  ['%'] = { tag = 'mod', prec = 13, assoc = LEFT_ASSOCIATIVE },
  ['^'] = { tag = 'exp', prec = 15, assoc = RIGHT_ASSOCIATIVE },
}

local BINOP_MAX_LEN = 1
for key, value in pairs(BINOPS) do
  BINOP_MAX_LEN = math.max(BINOP_MAX_LEN, #key)
end

-- -----------------------------------------------------------------------------
-- Return
-- TODO: use env here instead of copying over?
-- TODO: add Terminal words here
-- -----------------------------------------------------------------------------

return {
  EOF = -1,

  LEFT_ASSOCIATIVE = LEFT_ASSOCIATIVE,
  RIGHT_ASSOCIATIVE = RIGHT_ASSOCIATIVE,
  UNOPS = UNOPS,
  BINOPS = BINOPS,
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
