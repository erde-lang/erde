local _ENV = require('erde.parser.env').load()
local number = require('erde.parser.number')

-- -----------------------------------------------------------------------------
-- Constants
-- -----------------------------------------------------------------------------

local LEFT_ASSOCIATIVE = -1
local RIGHT_ASSOCIATIVE = 1

local PRECEDENCE_LEVELS = {
  -- Pipe
  -- Ternary
  { '??' },
  { '|' },
  { '&' },
  { '==', '~=', '<=', '>=', '<', '>' },
  { '.|' },
  { '.~' },
  { '.&' },
  { '.<<', '.>>' },
  { '..' },
  { '+', '-' },
  { '*', '//', '/', '%' },
  { '-' }, -- unary
  { '^' },
}

local OPERATORS = {
  {
    token = '+',
    associativity = LEFT_ASSOCIATIVE,
    precedence = 1,
  },
  {
    token = '-',
    associativity = LEFT_ASSOCIATIVE,
    precedence = 1,
  },
}

local OPTREE = {}

-- -----------------------------------------------------------------------------
-- Parse
--
-- Based on this amazing blog post:
-- https://eli.thegreenplace.net/2012/08/02/parsing-expressions-by-precedence-climbing
-- -----------------------------------------------------------------------------

local function parse_atom()
  local atom = { parens = false, value = nil }

  if bufValue == '(' then
    atom.parens = true
    atom.value = parse_expr()
    if bufValue ~= ')' then
      error('unbalanced parens')
    end
  elseif bufValue == EOF then
    error('unexpected EOF')
  else
    return atom.value = number.parse()
  end

  return atom
end

local function parse_op()
end

local function parse_expr(minPrecedence)
  local expr = parse_atom()



  return expr
end

local function parse()
  assert.state(STATE_EXPR)
  return parse_expr(0)
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  unit = function(input)
    loadBuffer(input)
    state = STATE_EXPR
    return parse()
  end,
  parse = parse,
}
