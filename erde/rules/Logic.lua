require('erde.env')()

return {
  If = {
    pattern = Pad('if') * CsV('Expr') * Pad('{') * CsV('Block') * Pad('}'),
    compiler = template('if %1 then %2'),
  },
  ElseIf = {
    pattern = Pad('elseif') * CsV('Expr') * Pad('{') * CsV('Block') * Pad('}'),
    compiler = template('elseif %1 then %2'),
  },
  Else = {
    pattern = Pad('else') * Pad('{') * CsV('Block') * Pad('}'),
    compiler = template('else %1'),
  },
  IfElse = {
    pattern = CsV('If') * CsV('ElseIf') ^ 0 * CsV('Else') ^ -1,
    compiler = function(...)
      return supertable({ ... }):push('end'):join(' ')
    end,
  },
  NumericFor = {
    pattern = Product({
      Pad('for'),
      CsV('Name'),
      Pad('='),
      List(CsV('Expr'), {
        minlen = 2,
        maxlen = 3,
        trailing = false,
      }),
      Pad('{'),
      CsV('Block'),
      Pad('}'),
    }),
    compiler = function(name, exprlist, block)
      return ('for %s = %s do %s end'):format(name, exprlist:join(','), block)
    end,
  },
  GenericFor = {
    pattern = Product({
      Pad('for'),
      CsV('Name'),
      Pad(','),
      CsV('Name'),
      Pad('in'),
      CsV('FunctionCall'),
      Pad('{'),
      CsV('Block'),
      Pad('}'),
    }),
    compiler = function(keyname, valuename, iterator, block)
      return ('for %s,%s in %s do %s end'):format(
        keyname,
        valuename,
        iterator,
        block
      )
    end,
  },
  WhileLoop = {
    pattern = Product({
      Pad('while'),
      CsV('Expr'),
      Pad('{'),
      CsV('Block'),
      Pad('}'),
    }),
    compiler = template('while %1 do %2 end'),
  },
  RepeatUntil = {
    pattern = Product({
      Pad('repeat'),
      Pad('{'),
      CsV('Block'),
      Pad('}'),
      Pad('until'),
      Pad('('),
      CsV('Expr'),
      Pad(')'),
    }),
    compiler = template('repeat %1 until (%2)'),
  },
  DoBlock = {
    pattern = Product({
      Pad('do'),
      Pad('{'),
      CsV('Block'),
      Pad('}'),
    }),
    compiler = template('do %1 end'),
  },
}
