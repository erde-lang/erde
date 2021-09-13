local inspect = require('inspect')
local lpeg = require('lpeg')
lpeg.locale(lpeg)
local compiler = require('compiler')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- Environment
--
-- Sets the fenv so that we don't have to prefix everything with `lpeg.` nor
-- manually destructure everything.
-- -----------------------------------------------------------------------------

setfenv(1, setmetatable(
  supertable(lpeg):filter(function(v, k) return _G[k] == nil end),
  { __index = _G }
))

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local state = {}

function state.reset()
  state.line = 1
  state.colstart = 0
end

function state.newline(position)
  state.colstart = position
  state.line = state.line + 1
end

-- -----------------------------------------------------------------------------
-- Rules
-- -----------------------------------------------------------------------------

local rules = supertable({ V('Block') })

function RuleSet(patterns)
  rules:merge(supertable(patterns):map(function(pattern, rule)
    return Cp() * pattern / function(position, ...)
      local node = supertable({ ... })
        :filter(function(value) return value ~= nil end)
        :merge({ rule = rule, position = position })
      return #node > 0 and node or nil
    end
  end))
end

-- -----------------------------------------------------------------------------
-- Rule Helpers
-- -----------------------------------------------------------------------------

local function Pad(pattern)
  return V('Space') * pattern * V('Space')
end

local function PadC(pattern)
  return V('Space') * C(pattern) * V('Space')
end

local function Csv(pattern, commacapture)
  local comma = commacapture and PadC(',') or Pad(',')
  return pattern * (comma * pattern) ^ 0 * Pad(',') ^ -1
end

local function Sum(patterns)
  return supertable(patterns):reduce(function(sum, pattern)
    return sum + pattern
  end, P(false))
end

local function Product(patterns)
  return supertable(patterns):reduce(function(product, pattern)
    return product * pattern
  end, P(true))
end

local function Demand(pattern)
  return pattern + Cc('__ERDE_ERROR__') * Cp() / function(capture, position)
    if capture == '__ERDE_ERROR__' then
      error(('Line %s, Column %s: Error'):format(
        state.line,
        position - state.colstart
      ))
    else
      return capture
    end
  end
end

-- -----------------------------------------------------------------------------
-- Rule Sets
-- -----------------------------------------------------------------------------

local Core = RuleSet({
  Keyword = Pad(Sum({
    P('local'),
    P('if'),
    P('elseif'),
    P('else'),
    P('false'),
    P('true'),
    P('nil'),
    P('return'),
  })),

  Name = C(-V('Keyword') * (alpha + P('_')) * (alnum + P('_')) ^ 0),
  Self = PadC('@'),
  SelfProperty = Pad(P('@') * V('Name')),

  IdBase = Sum({
    PadC('(') * V('Expr') * PadC(')'),
    V('Name'),
    V('SelfProperty'),
    V('Self'),
  }),
  Id = V('IdBase') * (V('IndexChain') + Cc(supertable())),
  IdExpr = V('Id'),

  Newline = P('\n') * (Cp() / state.newline),
  Space = (V('Newline') + space) ^ 0,

  Comment = Sum({
    Pad('--') * (P(1) - V('Newline')) ^ 0,
    Pad('--[[') * (P(1) - P(']]--')) ^ 0 * Pad(']]--'),
  }),

  Integer = digit ^ 1,
  Hex = (P('0x') + P('0X')) * xdigit ^ 1,
  Exponent = S('eE') * S('+-') ^ -1 * V('Integer'),
  Float = Sum({
    digit ^ 0 * P('.') * V('Integer') * V('Exponent') ^ -1,
    V('Integer') * V('Exponent'),
  }),
  Number = C(V('Float') + V('Hex') + V('Integer')),
})

local Strings = RuleSet({
  EscapedChar = C(V('Newline') + P('\\') * P(1)),

  Interpolation = P('{') * Pad(Demand(V('Expr'))) * P('}'),
  LongString = Product({
    P('`'),
    Sum({
      V('EscapedChar'),
      V('Interpolation'),
      C(P(1) - P('`')),
    }) ^ 0,
    P('`'),
  }),

  String = Sum({
    V('LongString'),
    C("'") * (V('EscapedChar') + C(1) - P("'")) ^ 0 * C("'"), -- single quote
    C('"') * (V('EscapedChar') + C(1) - P('"')) ^ 0 * C('"'), -- double quote
  }),
})

local Tables = RuleSet({
  StringTableKey = V('String'),
  MapTableField = (V('StringTableKey') + V('Name')) * Pad(':') * V('Expr'),
  InlineTableField = Pad(P(':') * V('Name')),
  TableField = V('InlineTableField') + V('MapTableField') + V('Expr'),
  Table = PadC('{') * (Csv(V('TableField'), true) + V('Space')) * PadC('}'),

  DotIndex = V('Space') * C('.') * V('Name'),
  BracketIndex = PadC('[') * V('Expr') * PadC(']'),
  Index = Product({
    Pad('?') * Cc(true) + Cc(false),
    V('DotIndex') + V('BracketIndex'),
  }),
  IndexChain = V('Index') ^ 1,

  Destruct = Product({
    C(':') + Cc(false),
    V('Name'),
    V('Destructure') + Cc(false),
    (Pad('=') * Demand(V('Expr'))) + Cc(false),
  }),
  Destructure = Pad('{') * Csv(V('Destruct')) * Pad('}'),
})

local Functions = RuleSet({
  Arg = Sum({
    Cc(false) * V('Name'),
    Cc(true) * V('Destructure'),
  }),
  OptArg = V('Arg') * Pad('=') * V('Expr'),
  VarArgs = Pad('...') * V('Name') ^ -1,
  ParamComma = (#Pad(')') * Pad(',') ^ -1) + Pad(','),
  Params = V('Arg') + Product({
    Pad('('),
    (V('Arg') * V('ParamComma')) ^ 0,
    (V('OptArg') * V('ParamComma')) ^ 0,
    (V('VarArgs') * V('ParamComma')) ^ -1,
    Cc({}),
    Pad(')'),
  }),

  FunctionExprBody = V('Expr'),
  FunctionBody = Pad('{') * V('Block') * Pad('}') + V('FunctionExprBody'),
  Function = Sum({
    Cc(false) * V('Params') * Pad('->') * V('FunctionBody'),
    Cc(true) * V('Params') * Pad('=>') * V('FunctionBody'),
  }),

  ReturnList = Pad('(') * V('ReturnList') * Pad(')') + Csv(V('Expr')),
  Return = PadC('return') * V('ReturnList') ^ -1,

  FunctionCall = Product({
    V('IdExpr'),
    (PadC(':') * V('Name')) ^ -1,
    PadC('('),
    Csv(V('Expr'), true) + V('Space'),
    PadC(')'),
  }),
})

local LogicFlow = RuleSet({
  If = Pad('if') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  ElseIf = Pad('elseif') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  Else = Pad('else') * Pad('{') * V('Block') * Pad('}'),
  IfElse = V('If') * V('ElseIf') ^ 0 * V('Else') ^ -1,
})

local Expressions = RuleSet({
  SubExpr = Sum({
    V('FunctionCall'),
    V('Function'),
    V('IdExpr'),
    V('Table'),
    V('String'),
    V('Number'),
    PadC('true'),
    PadC('false'),
  }),

  Expr = Sum({
    V('Operation'),
    V('SubExpr'),
  }),
})

local Operators = RuleSet({
  TernaryOp = V('SubExpr') * Pad('?') * V('Expr') * (Pad(':') * V('Expr')) ^ -1,
  UnaryOp = PadC(S('~-#')) * V('Expr'),
  Binop = V('SubExpr') * Product({
    PadC(Sum({
      '+', '-', '*', '//', '/', '^', '%', -- arithmetic
      '.|', '.&', '.~', '.>>', '.<<',     -- bitwise
      '==', '~=', '<=', '>=', '<', '>',   -- relational
      '&', '|', '..', '??',               -- misc
    })),
    V('Expr'),
  }),
  AssignOp = Product({
    V('Id'),
    Pad(C(Sum({
      '+', '-', '*', '//', '/', '^', '%', -- arithmetic
      '.|', '.&', '.~', '.>>', '.<<',     -- bitwise
      '&', '|', '..', '??',               -- misc
    })) * P('=')),
    V('Expr'),
  }),
  Operation = Sum({
    V('UnaryOp'),
    V('TernaryOp'),
    V('Binop'),
    V('AssignOp'),
  }),
})

local Declaration = RuleSet({
  NameDeclaration = Product({
    PadC('local') + C(false),
    V('Name'),
    (PadC('=') * Demand(V('Expr'))) ^ -1,
  }),

  VarArgsDeclaration = Product({
    PadC('local') + C(false),
    Pad('...'),
    V('Name'),
    Demand(Pad('=') * V('Expr')),
  }),

  DestructureDeclaration = Product({
    PadC('local') + C(false),
    V('Destructure'),
    Demand(Pad('=') * V('Expr')),
  }),

  Assignment = V('Id') * Pad('=') * V('Expr'),

  Declaration = Sum({
    V('Assignment'),
    V('DestructureDeclaration'),
    V('VarArgsDeclaration'),
    V('NameDeclaration'),
  }),
})

local Blocks = RuleSet({
  Block = V('Statement') ^ 1 + Pad(Cc('')),
  Statement = Pad(Sum({
    V('FunctionCall'),
    V('Declaration'),
    V('AssignOp'),
    V('Return'),
    V('IfElse'),
    V('Comment'),
  })),
})

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

local grammar = P(rules)

return function(subject)
  lpeg.setmaxstack(1000)
  state.reset()
  local ast = grammar:match(subject, nil, {})
  return ast or {}, state
end
