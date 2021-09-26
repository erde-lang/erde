local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  IfElse = {
    pattern = _.Product({
      _.Cc(1) * _.Product({
        _.Pad('if'),
        _.CsV('Expr'),
        _.Pad('{'),
        _.CsV('Block'),
        _.Pad('}'),
      }) / _.map('variant', 'expr', 'block'),
      (
        _.Cc(2) * _.Product({
          _.Pad('elseif'),
          _.CsV('Expr'),
          _.Pad('{'),
          _.CsV('Block'),
          _.Pad('}'),
        }) / _.map('variant', 'expr', 'block')
      ) ^ 0,
      (
        _.Cc(3) * _.Product({
          _.Pad('else'),
          _.Pad('{'),
          _.CsV('Block'),
          _.Pad('}'),
        }) / _.map('variant', 'block')
      ) ^ -1,
    }) / _.pack,
    compiler = function(conditionals)
      return conditionals:map(function(cond)
        if cond.variant == 1 then
          return 'if '..cond.expr..' then '..cond.block
        elseif cond.variant == 2 then
          return 'elseif '..cond.expr..' then '..cond.block
        elseif cond.variant == 3 then
          return 'else '..cond.block
        end
      end):push('end'):join(' ')
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
      _.CsV('Expr'),
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
