local grammar = {}

local lpeg = require('lpeg')
local scope = require('__scope')
local _ = require('utils')

lpeg.locale(lpeg)

local P, S, V = lpeg.P, lpeg.S, lpeg.V
local C, Carg, Cb, Cc = lpeg.C, lpeg.Carg, lpeg.Cb, lpeg.Cc
local Cf, Cg, Cmt, Cp, Ct = lpeg.Cf, lpeg.Cg, lpeg.Cmt, lpeg.Cp, lpeg.Ct
local alpha, digit, alnum = lpeg.alpha, lpeg.digit, lpeg.alnum
local xdigit = lpeg.xdigit
local space = lpeg.space

local lineno = scope.lineno
local new_scope, end_scope = scope.new_scope, scope.end_scope
local new_function, end_function = scope.new_function, scope.end_function
local begin_loop, end_loop = scope.begin_loop, scope.end_loop
local insideloop = scope.insideloop

-- -----------------------------------------------------------------------------
-- Legacy Helpers (DO NOT TOUCH)
-- -----------------------------------------------------------------------------

-- gets the farthest failure position
local function getffp(s, i, t)
  return t.ffp or i, t
end

local function report_error()
  return Cmt(Carg(1), getffp) * (C(V('OneWord')) + Cc('EOF')) / function(t, u)
    t.unexpected = u
    return t
  end / function(t)
    return 'ERROR', t
  end
end

-- sets the farthest failure position and the expected tokens
local function setffp(s, i, t, n)
  if not t.ffp or i > t.ffp then
    t.ffp = i
    t.list = {}
    t.list[n] = n
    t.expected = "'" .. n .. "'"
  elseif i == t.ffp then
    if not t.list[n] then
      t.list[n] = n
      t.expected = "'" .. n .. "', " .. t.expected
    end
  end
  return false
end

local function updateffp(name)
  return Cmt(Carg(1) * Cc(name), setffp)
end

-- regular combinators and auxiliary functions

local function token(pat, name)
  return pat * V('Skip') + updateffp(name) * P(false)
end

local function symb(str)
  return token(P(str), str)
end

local function kw(str)
  return token(P(str) * -V('WordChar'), str)
end

local function taggedCap(tag, pat)
  return Ct(Cg(Cp(), 'pos') * Cg(Cc(tag), 'tag') * pat)
end

local function unaryop(op, e)
  return { tag = 'Op', pos = e.pos, [1] = op, [2] = e }
end

local function binaryop(e1, op, e2)
  if not op then
    return e1
  elseif
    op == 'add'
    or op == 'sub'
    or op == 'mul'
    or op == 'div'
    or op == 'idiv'
    or op == 'mod'
    or op == 'pow'
    or op == 'concat'
    or op == 'band'
    or op == 'bor'
    or op == 'bxor'
    or op == 'shl'
    or op == 'shr'
    or op == 'eq'
    or op == 'lt'
    or op == 'le'
    or op == 'and'
    or op == 'or'
  then
    return { tag = 'Op', pos = e1.pos, [1] = op, [2] = e1, [3] = e2 }
  elseif op == 'ne' then
    return unaryop('not', {
      tag = 'Op',
      pos = e1.pos,
      [1] = 'eq',
      [2] = e1,
      [3] = e2,
    })
  elseif op == 'gt' then
    return { tag = 'Op', pos = e1.pos, [1] = 'lt', [2] = e2, [3] = e1 }
  elseif op == 'ge' then
    return { tag = 'Op', pos = e1.pos, [1] = 'le', [2] = e2, [3] = e1 }
  end
end

local function chainl(pat, sep, a)
  return Cf(pat * Cg(sep * pat) ^ 0, binaryop) + a
end

local function chainl1(pat, sep)
  return Cf(pat * Cg(sep * pat) ^ 0, binaryop)
end

local function sepby(pat, sep, tag)
  return taggedCap(tag, (pat * (sep * pat) ^ 0) ^ -1)
end

local function sepby1(pat, sep, tag)
  return taggedCap(tag, pat * (sep * pat) ^ 0)
end

local function fix_str(str)
  str = string.gsub(str, '\\a', '\a')
  str = string.gsub(str, '\\b', '\b')
  str = string.gsub(str, '\\f', '\f')
  str = string.gsub(str, '\\n', '\n')
  str = string.gsub(str, '\\r', '\r')
  str = string.gsub(str, '\\t', '\t')
  str = string.gsub(str, '\\v', '\v')
  str = string.gsub(str, '\\\n', '\n')
  str = string.gsub(str, '\\\r', '\n')
  str = string.gsub(str, "\\'", "'")
  str = string.gsub(str, '\\"', '"')
  str = string.gsub(str, '\\\\', '\\')
  return str
end

-- -----------------------------------------------------------------------------
-- Extended Pattern Helpers
-- -----------------------------------------------------------------------------

local function exact(pattern, n)
  return (pattern ^ n) ^ -n
end

local function pad(pattern, min_spaces)
  min_spaces = min_spaces or 0
  return (space ^ min_spaces) * pattern * (space ^ min_spaces)
end

local function symbol(s)
  return pad(P(s))
end

-- -----------------------------------------------------------------------------
-- List Helpers
-- -----------------------------------------------------------------------------

local function list(pattern, separator)
  separator = separator or symbol(',')
  return pattern * (separator * pattern) ^ 0
end

local function join(patterns, separator)
  separator = separator or symbol(',')

  if #patterns == 0 then
    return P(true)
  end

  local joined = patterns[1]
  for i = 2, #patterns do
    joined = joined * separator * patterns[i]
  end
  return joined
end

local function sum(patterns)
  if #patterns == 0 then
    return P(true)
  end

  local summed = patterns[1]
  for i = 2, #patterns do
    summed = summed + patterns[i]
  end
  return summed
end

-- -----------------------------------------------------------------------------
-- Misc Helpers
-- -----------------------------------------------------------------------------

local function keyword(s)
  return P(s) * -V('WordChar') * V('Skip')
end

local function tag(tag, pattern)
  return Ct(Cg(Cp(), 'pos') * Cg(Cc(tag), 'tag') * pattern)
end

-- -----------------------------------------------------------------------------
-- Grammar
-- -----------------------------------------------------------------------------

return P({
  V('Lua'),
  Lua = V('Shebang') ^ -1 * V('Skip') * V('Chunk') * -1 + report_error(),
  Shebang = P('#') * (P(1) - P('\n')) ^ 0 * P('\n'),

  --
  -- Syntax
  --

  Chunk = V('Block'),
  Block = taggedCap('Block', V('StatList') * V('RetStat') ^ -1),
  StatList = (symb(';') + V('Stat')) ^ 0,

  --
  -- Words
  --

  WordChar = alnum + P('_'),

  Keyword = keyword('and') + keyword('break') + keyword('do') + keyword('else') + keyword('elseif') + keyword('end') + keyword('false') + keyword('for') + keyword('function') + keyword('goto') + keyword('if') + keyword('in') + keyword('local') + keyword('nil') + keyword('not') + keyword('or') + keyword('repeat') + keyword('return') + keyword('then') + keyword('true') + keyword('until') + keyword('while'),

  Identifier = -V('Keyword') * C((alpha + P('_')) * V('WordChar') ^ 0),
  IdentifierList = V('Identifier') * (pad(',') * V('Identifier')) ^ 0,

  -- TODO: deprecate
  Id = taggedCap('Id', token(V('Name'), 'Name')),
  Name = -V('Keyword') * C(V('Identifier')) * -V('WordChar'),
  NameList = sepby1(V('Id'), symb(','), 'NameList'),

  --
  -- Operations
  --

  OrOp = kw('or') / 'or',
  AndOp = kw('and') / 'and',
  RelOp = symb('~=') / 'ne' + symb('==') / 'eq' + symb('<=') / 'le' + symb('>=') / 'ge' + symb('<') / 'lt' + symb('>') / 'gt',
  BOrOp = symb('|') / 'bor',
  BXorOp = symb('~') / 'bxor',
  BAndOp = symb('&') / 'band',
  ShiftOp = symb('<<') / 'shl' + symb('>>') / 'shr',
  ConOp = symb('..') / 'concat',
  AddOp = symb('+') / 'add' + symb('-') / 'sub',
  MulOp = symb('*') / 'mul' + symb('//') / 'idiv' + symb('/') / 'div' + symb('%') / 'mod',
  UnOp = kw('not') / 'not' + symb('-') / 'unm' + symb('#') / 'len' + symb('~') / 'bnot',
  PowOp = symb('^') / 'pow',

  --
  -- Strings
  --

  EscapedChar = P('\\') * P(1),

  SingleQuoteString = P("'") * C((V('EscapedChar') + (P(1) - P("'"))) ^ 0) * P("'"),
  DoubleQuoteString = P('"') * C((V('EscapedChar') + (P(1) - P('"'))) ^ 0) * P('"'),
  ShortString = V('SingleQuoteString') + V('DoubleQuoteString'),

  LongString = V('Open') * C((P(1) - V('CloseEQ')) ^ 0) * V('Close') / function(s, o)
    return s
  end,

  String = V('LongString') + (V('ShortString') / function(s)
    return fix_str(s)
  end),

  --
  -- Conditionals
  --

  IfStat = taggedCap(
    'If',
    kw('if')
      * V('Expr')
      * kw('then')
      * V('Block')
      * (kw('elseif') * V('Expr') * kw('then') * V('Block')) ^ 0
      * (kw('else') * V('Block')) ^ -1
      * kw('end')
  ),

  --
  -- Loops
  --

  ForBody = keyword('do') * V('Block'),
  ForNum = taggedCap(
    'Fornum',
    V('Id')
      * symb('=')
      * V('Expr')
      * symb(',')
      * V('Expr')
      * (symb(',') * V('Expr')) ^ -1
      * V('ForBody')
  ),
  ForGen = taggedCap(
    'Forin',
    V('NameList') * kw('in') * V('ExpList') * V('ForBody')
  ),

  ForStat = kw('for') * (V('ForNum') + V('ForGen')) * kw('end'),

  DoStat = kw('do') * V('Block') * kw('end') / function(t)
    t.tag = 'Do'
    return t
  end,

  WhileStat = taggedCap(
    'While',
    kw('while') * V('Expr') * kw('do') * V('Block') * kw('end')
  ),

  RepeatStat = taggedCap(
    'Repeat',
    kw('repeat') * V('Block') * kw('until') * V('Expr')
  ),

  --
  -- Functions
  --

  FuncArgs = symb('(') * (V('Expr') * (symb(',') * V('Expr')) ^ 0) ^ -1 * symb(')') + V('Constructor') + taggedCap(
    'String',
    token(V('String'), 'String')
  ),

  FuncName = Cf(
    V('Id') * (symb('.') * taggedCap('String', token(V('Name'), 'Name'))) ^ 0,
    function(t1, t2)
      if t2 then
        return { tag = 'Index', pos = t1.pos, [1] = t1, [2] = t2 }
      end
      return t1
    end
  ) * (symb(':') * taggedCap('String', token(V('Name'), 'Name'))) ^ -1 / function(t1, t2)
    if t2 then
      return { tag = 'Index', pos = t1.pos, is_method = true, [1] = t1, [2] = t2 }
    end
    return t1
  end,

  -- Cc({}) generates a strange bug when parsing [[function t:a() end ; function t.a() end]]
  -- the bug is to add the parameter self to the second function definition
  --FuncBody = taggedCap("Function", symb("(") * (V"ParList" + Cc({})) * symb(")") * V"Block" * kw("end"));
  FuncBody = taggedCap('Function', V('Parameters') * V('Block') * kw('end')),

  FuncStat = taggedCap('Set', kw('function') * V('FuncName') * V('FuncBody')) / function(t)
    if t[1].is_method then
      table.insert(t[2][1], 1, { tag = 'Id', [1] = 'self' })
    end
    t[1] = { t[1] }
    t[2] = { t[2] }
    return t
  end,

  LocalFunc = taggedCap('Localrec', kw('function') * V('Id') * V('FuncBody')) / function(t)
    t[1] = { t[1] }
    t[2] = { t[2] }
    return t
  end,

  FunctionDef = kw('function') * V('FuncBody'),

  Arg = V('Identifier'),
  Args = tag('Args', list(V('Arg') - V('OptArg'))),
  OptArg = V('Arg') * symbol('=') * V('Expr'),
  OptArgs = tag('OptArgs', list(V('OptArg'))),
  VarArgs = tag('VarArgs', symbol('...') * V('Identifier') ^ 0),

  Parameters = tag(
    'Parameters',
    _.reduce({
      join({ V('Args'), V('OptArgs'), V('VarArgs') }),
      join({ V('Args'), V('OptArgs') }),
      join({ V('Args'), V('VarArgs') }),
      join({ V('OptArgs'), V('VarArgs') }),
      V('Args'),
      V('OptArgs'),
      V('VarArgs'),
      P(true),
    }, function(pattern, subpattern)
      return pattern + symbol('(') * subpattern * symbol(')')
    end, P(false))
  ),

  --
  -- Expressions
  --

  Expr = V('SubExpr_1'),

  PrimaryExp = V('Var') + taggedCap('Paren', symb('(') * V('Expr') * symb(')')),

  SubExpr_1 = chainl1(V('SubExpr_2'), V('OrOp')),
  SubExpr_2 = chainl1(V('SubExpr_3'), V('AndOp')),
  SubExpr_3 = chainl1(V('SubExpr_4'), V('RelOp')),
  SubExpr_4 = chainl1(V('SubExpr_5'), V('BOrOp')),
  SubExpr_5 = chainl1(V('SubExpr_6'), V('BXorOp')),
  SubExpr_6 = chainl1(V('SubExpr_7'), V('BAndOp')),
  SubExpr_7 = chainl1(V('SubExpr_8'), V('ShiftOp')),
  SubExpr_8 = V('SubExpr_9') * V('ConOp') * V('SubExpr_8') / binaryop + V('SubExpr_9'),
  SubExpr_9 = chainl1(V('SubExpr_10'), V('AddOp')),
  SubExpr_10 = chainl1(V('SubExpr_11'), V('MulOp')),
  SubExpr_11 = V('UnOp') * V('SubExpr_11') / unaryop + V('SubExpr_12'),
  SubExpr_12 = V('SimpleExp') * (V('PowOp') * V('SubExpr_11')) ^ -1 / binaryop,

  SimpleExp = taggedCap('Number', token(V('Number'), 'Number')) + taggedCap(
    'String',
    token(V('String'), 'String')
  ) + taggedCap('Nil', kw('nil')) + taggedCap('False', kw('false')) + taggedCap(
    'True',
    kw('true')
  ) + taggedCap('Dots', symb('...')) + V('FunctionDef') + V('Constructor') + V('SuffixedExp'),

  SuffixedExp = Cf(
    V('PrimaryExp') * (taggedCap(
      'DotIndex',
      symb('.') * taggedCap('String', token(V('Name'), 'Name'))
    ) + taggedCap('ArrayIndex', symb('[') * V('Expr') * symb(']')) + taggedCap(
      'Invoke',
      Cg(
        symb(':')
          * taggedCap('String', token(V('Name'), 'Name'))
          * V('FuncArgs')
      )
    ) + taggedCap('Call', V('FuncArgs'))) ^ 0,
    function(t1, t2)
      if t2 then
        if t2.tag == 'Call' or t2.tag == 'Invoke' then
          local t = { tag = t2.tag, pos = t1.pos, [1] = t1 }
          for k, v in ipairs(t2) do
            table.insert(t, v)
          end
          return t
        else
          return { tag = 'Index', pos = t1.pos, [1] = t1, [2] = t2[1] }
        end
      end
      return t1
    end
  ),

  ExpList = sepby1(V('Expr'), symb(','), 'ExpList'),

  ExprStat = Cmt(
    (V('SuffixedExp') * (Cc(function(...)
      local vl = { ... }
      local el = vl[#vl]
      table.remove(vl)
      for k, v in ipairs(vl) do
        if v.tag == 'Id' or v.tag == 'Index' then
          vl[k] = v
        else
          -- invalid assignment
          return false
        end
      end
      vl.tag = 'VarList'
      vl.pos = vl[1].pos
      return true, { tag = 'Set', pos = vl.pos, [1] = vl, [2] = el }
    end) * V('Assignment'))) + (V('SuffixedExp') * (Cc(function(s)
      if s.tag == 'Call' or s.tag == 'Invoke' then
        return true, s
      end
      -- invalid statement
      return false
    end))),
    function(s, i, s1, f, ...)
      return f(s1, ...)
    end
  ),

  --
  -- Other
  --

  Skip = (V('Space') + V('Comment')) ^ 0,

  --
  -- TODO
  --

  Var = V('Id'),
  FieldSep = symb(',') + symb(';'),
  Field = taggedCap(
    'Pair',
    (symb('[') * V('Expr') * symb(']') * symb('=') * V('Expr')) + (taggedCap(
      'String',
      token(V('Name'), 'Name')
    ) * symb('=') * V('Expr'))
  ) + V('Expr'),
  FieldList = (V('Field') * (V('FieldSep') * V('Field')) ^ 0 * V('FieldSep') ^ -1) ^ -1,
  Constructor = taggedCap('Table', symb('{') * V('FieldList') * symb('}')),
  LocalAssign = taggedCap(
    'Local',
    V('NameList') * ((symb('=') * V('ExpList')) + Ct(Cc()))
  ),
  LocalStat = kw('local') * (V('LocalFunc') + V('LocalAssign')),
  LabelStat = taggedCap(
    'Label',
    symb('::') * token(V('Name'), 'Name') * symb('::')
  ),
  BreakStat = taggedCap('Break', kw('break')),
  GoToStat = taggedCap('Goto', kw('goto') * token(V('Name'), 'Name')),
  RetStat = taggedCap(
    'Return',
    kw('return')
      * (V('Expr') * (symb(',') * V('Expr')) ^ 0) ^ -1
      * symb(';') ^ -1
  ),
  Assignment = ((symb(',') * V('SuffixedExp')) ^ 1) ^ -1 * symb('=') * V('ExpList'),
  Stat = V('IfStat') + V('WhileStat') + V('DoStat') + V('ForStat') + V('RepeatStat') + V('FuncStat') + V('LocalStat') + V('LabelStat') + V('BreakStat') + V('GoToStat') + V('ExprStat'),
  -- lexer
  Space = space ^ 1,
  Equals = P('=') ^ 0,
  Open = '[' * Cg(V('Equals'), 'init') * '[' * P('\n') ^ -1,
  Close = ']' * C(V('Equals')) * ']',
  CloseEQ = Cmt(V('Close') * Cb('init'), function(s, i, a, b)
    return a == b
  end),
  Comment = P('--') * V('LongString') / function()
    return
  end + P('--') * (P(1) - P('\n')) ^ 0,
  Hex = (P('0x') + P('0X')) * xdigit ^ 1,
  Expo = S('eE') * S('+-') ^ -1 * digit ^ 1,
  Float = (((digit ^ 1 * P('.') * digit ^ 0) + (P('.') * digit ^ 1)) * V('Expo') ^ -1) + (digit ^ 1 * V('Expo')),
  Int = digit ^ 1,
  Number = C(V('Hex') + V('Float') + V('Int')) / function(n)
    return tonumber(n)
  end,
  -- for error reporting
  OneWord = V('Name') + V('Number') + V('String') + V('Keyword') + P('...') + P(1),
})
