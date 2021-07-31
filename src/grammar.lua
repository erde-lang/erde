local lpeg = require('lpeg')
local lspeg = require('lspeg')

local scope = require('__scope')
local _ = require('utils')

lpeg.locale(lpeg)
local E, P, S, V = lpeg.E, lpeg.P, lpeg.S, lpeg.V
local C, Carg, Cb, Cc, Cf, Cg, Cmt, Cp, Ct = lpeg.C,
  lpeg.Carg,
  lpeg.Cb,
  lpeg.Cc,
  lpeg.Cf,
  lpeg.Cg,
  lpeg.Cmt,
  lpeg.Cp,
  lpeg.Ct
local alpha, digit, alnum, space, xdigit =
  lpeg.alpha, lpeg.digit, lpeg.alnum, lpeg.space, lpeg.xdigit

local E, W = lspeg.E, lspeg.W
local L, Lj = lspeg.L, lspeg.Lj
local T = lspeg.T

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

  Stat = _.reduce({
    'If',
    'WhileStat',
    'DoStat',
    'For',
    'RepeatStat',
    'FuncStat',
    'LocalStat',
    'LabelStat',
    'BreakStat',
    'GoToStat',
    'ExprStat',
  }, function(Stat, SubStat)
    return Stat + V(SubStat)
  end, P(false)),
  StatList = (symb(';') + V('Stat')) ^ 0,

  --
  -- Words
  --

  WordChar = alnum + P('_'),

  Keyword = _.reduce({
    'and',
    'break',
    'do',
    'else',
    'elseif',
    'end',
    'false',
    'for',
    'function',
    'goto',
    'if',
    'in',
    'local',
    'nil',
    'not',
    'or',
    'repeat',
    'return',
    'then',
    'true',
    'until',
    'while',
  }, function(keywords, keyword)
    return keywords + W(keyword)
  end, P(false)),

  Identifier = -V('Keyword') * C((alpha + P('_')) * V('WordChar') ^ 0),

  -- TODO: deprecate
  Id = taggedCap('Id', token(V('Name'), 'Name')),
  Name = -V('Keyword') * C(V('Identifier')) * -V('WordChar'),
  NameList = sepby1(V('Id'), symb(','), 'NameList'),

  --
  -- Strings
  --
  -- TODO: LongString magic docs
  -- TODO: rename LongStringId?
  -- TODO: doc / workaraound string escaped char fixing?
  --
  -- http://www.inf.puc-rio.br/~roberto/lpeg
  -- Example: Lua's long strings
  --

  EscapedChar = P('\\') * P(1),

  SingleQuoteString = P("'") * C((V('EscapedChar') + (P(1) - P("'"))) ^ 0) * P("'"),
  DoubleQuoteString = P('"') * C((V('EscapedChar') + (P(1) - P('"'))) ^ 0) * P('"'),
  ShortString = V('SingleQuoteString') + V('DoubleQuoteString'),

  LongStringStart = '[' * Cg(P('=') ^ 0, 'LongStringId') * '[',
  LongStringEnd = ']' * P('=') ^ 0 * ']',
  LongStringIdCheck = Cmt(
    V('LongStringEnd') * Cb('LongStringId'),
    function(s, i, a, b)
      return a == b
    end
  ),
  LongString = V('LongStringStart') * C((P(1) - V('LongStringEnd')) ^ 0) * V('LongStringEnd'),

  String = V('LongString') + (V('ShortString') / function(s)
    return s
      :gsub('\\a', '\a')
      :gsub('\\b', '\b')
      :gsub('\\f', '\f')
      :gsub('\\n', '\n')
      :gsub('\\r', '\r')
      :gsub('\\t', '\t')
      :gsub('\\v', '\v')
      :gsub('\\\\', '\\')
      :gsub('\\"', '"')
      :gsub("\\'", "'")
      :gsub('\\[', '[')
      :gsub('\\]', ']')
  end),

  --
  -- Logic Flow
  --

  If = T(
    'If',
    W('if')
      * V('Expr')
      * W('then')
      * V('Block')
      * (W('elseif') * V('Expr') * W('then') * V('Block')) ^ 0
      * (W('else') * V('Block')) ^ -1
      * W('end')
  ),

  NumericFor = V('Identifier') * W('=') * V('Expr') * symb(',') * V('Expr') * (W(',') * V('Expr')) ^ -1,
  GenericFor = L(V('Identifier')) * W('in') * L(V('Expr')),
  For = W('for') * (V('NumericFor') + V('GenericFor')) * W('do') * V('Block') * W('end'),

  DoStat = W('do') * T('Do', V('Block')) * W('end'),

  WhileStat = T(
    'While',
    W('while') * V('Expr') * W('do') * V('Block') * W('end')
  ),

  RepeatStat = T(
    'Repeat',
    W('repeat') * V('Block') * W('until') * V('Expr')
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
  Args = T('Args', L(V('Arg') - V('OptArg'))),
  OptArg = V('Arg') * W('=') * V('Expr'),
  OptArgs = T('OptArgs', L(V('OptArg'))),
  VarArgs = T('VarArgs', W('...') * V('Identifier') ^ 0),

  Parameters = T(
    'Parameters',
    _.reduce({
      Lj({ V('Args'), V('OptArgs'), V('VarArgs') }),
      Lj({ V('Args'), V('OptArgs') }),
      Lj({ V('Args'), V('VarArgs') }),
      Lj({ V('OptArgs'), V('VarArgs') }),
      V('Args'),
      V('OptArgs'),
      V('VarArgs'),
      P(true),
    }, function(pattern, subpattern)
      return pattern + W('(') * subpattern * W(')')
    end, P(false))
  ),

  AnonymousFunction = W('function') * V('Parameters') * V('Block') * W('end'),
  FatLambda = T('FatLambda', V('Parameters') * W('=>') * V('Expr')),
  SkinnyLambda = T('SkinnyLambda', V('Parameters') * W('->') * V('Expr')),
  FunctionExpression = V('AnonymousFunction') + V('SkinnyLambda') + V('FatLambda'),

  --
  -- Operations
  --

  OrOp = W('or'),
  AndOp = W('and'),
  RelOp = W('~=') / 'ne' + W('==') / 'eq' + W('<=') / 'le' + W('>=') / 'ge' + W('<') / 'lt' + W('>') / 'gt',
  BOrOp = W('|') / 'bor',
  BXorOp = W('~') / 'bxor',
  BAndOp = W('&') / 'band',
  ShiftOp = W('<<') / 'shl' + W('>>') / 'shr',
  ConOp = W('..') / 'concat',
  AddOp = W('+') / 'add' + W('-') / 'sub',
  MulOp = W('*') / 'mul' + W('//') / 'idiv' + W('/') / 'div' + W('%') / 'mod',
  UnOp = W('not') / 'not' + W('-') / 'unm' + W('#') / 'len' + W('~') / 'bnot',
  PowOp = W('^') / 'pow',

  --
  -- Expressions
  --

  Expr = V('SubExpr_1') + V('FunctionExpression'),

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

  Comment = P('--') * V('LongString') / function()
    return
  end + P('--') * (P(1) - P('\n')) ^ 0,
  Skip = (space + V('Comment')) ^ 0,

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
  -- lexer
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
