local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  If = {
    pattern = _.Pad('if') * _.CsV('Expr') * _.Pad('{') * _.CsV('Block') * _.Pad('}'),
    compiler = _.template('if %1 then %2'),
  },
  ElseIf = {
    pattern = _.Pad('elseif') * _.CsV('Expr') * _.Pad('{') * _.CsV('Block') * _.Pad('}'),
    compiler = _.template('elseif %1 then %2'),
  },
  Else = {
    pattern = _.Pad('else') * _.Pad('{') * _.CsV('Block') * _.Pad('}'),
    compiler = _.template('else %1'),
  },
  IfElse = {
    pattern = _.CsV('If') * _.CsV('ElseIf') ^ 0 * _.CsV('Else') ^ -1,
    compiler = function(...)
      return supertable({ ... }):push('end'):join(' ')
    end,
  },
  NumericFor = {
    pattern = _.Product({
      _.Pad('for'),
      _.CsV('Name'),
      _.Pad('='),
      _.List(_.CsV('Expr'), {
        minlen = 2,
        maxlen = 3,
        trailing = false,
      }),
      _.Pad('{'),
      _.CsV('Block'),
      _.Pad('}'),
    }),
    compiler = function(name, exprlist, block)
      return ('for %s = %s do %s end'):format(name, exprlist:join(','), block)
    end,
  },
  GenericFor = {
    pattern = _.Product({
      _.Pad('for'),
      _.CsV('Name'),
      _.Pad(','),
      _.CsV('Name'),
      _.Pad('in'),
      _.CsV('FunctionCall'),
      _.Pad('{'),
      _.CsV('Block'),
      _.Pad('}'),
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
    pattern = _.Product({
      _.Pad('while'),
      _.CsV('Expr'),
      _.Pad('{'),
      _.CsV('Block'),
      _.Pad('}'),
    }),
    compiler = _.template('while %1 do %2 end'),
  },
  RepeatUntil = {
    pattern = _.Product({
      _.Pad('repeat'),
      _.Pad('{'),
      _.CsV('Block'),
      _.Pad('}'),
      _.Pad('until'),
      _.Pad('('),
      _.CsV('Expr'),
      _.Pad(')'),
    }),
    compiler = _.template('repeat %1 until (%2)'),
  },
  DoBlock = {
    pattern = _.Product({
      _.Pad('do'),
      _.Pad('{'),
      _.CsV('Block'),
      _.Pad('}'),
    }),
    compiler = _.template('do %1 end'),
  },
}
