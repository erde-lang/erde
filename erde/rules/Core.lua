local _ = require('erde.rules.helpers')
local state = require('erde.state')
local supertable = require('erde.supertable')

return {
  Newline = {
    pattern = _.P('\n') * (_.Cp() / function(position)
      state.currentline = state.currentline + 1
      state.currentlinestart = position
    end),
  },
  Space = {
    pattern = (_.V('Newline') + _.space) ^ 0,
  },
  Comment = {
    pattern = _.Sum({
      _.Pad('---') * (_.P(1) - _.P('---')) ^ 0 * _.Pad('---'),
      _.Pad('--') * (_.P(1) - _.V('Newline')) ^ 0,
    }),
    compiler = function()
      return ''
    end,
  },
  Name = {
    pattern = _.Product({
      -_.Pad(_.Sum({
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
        'false',
        'true',
        'nil',
        'return',
      })),
      _.alpha + _.P('_'),
      (_.alnum + _.P('_')) ^ 0,
    }),
  },
  IndexChain = {
    pattern = function()
      local ArgList = _.Parens(_.List(_.CsV('Expr')))
      return (
        _.Product({
          _.Pad('?') * _.Cc(true) + _.Cc(false),
          _.Sum({
            _.Cc(1) * _.Pad('.') * _.CsV('Name'),
            _.Cc(2) * _.Pad('[') * _.CsV('Expr') * _.Pad(']'),
            _.Cc(3) * ArgList,
            _.Cc(4) * _.Product({
              _.Pad(':'),
              _.CsV('Name'),
              #(_.Pad('?') ^ -1 * ArgList) + _.Expect(false),
            }),
          }),
        }) / _.map('opt', 'variant', 'value')
      ) ^ 0 / _.pack
    end
  },
  Id = {
    pattern = _.Sum({
      _.Parens(_.CsV('Expr')),
      _.CsV('Name'),
    }) * _.V('IndexChain'),
  },
  IdExpr = {
    pattern = _.V('Id'),
    compiler = _.indexchain(_.template('%1'), _.template('return %1')),
  },
  Return = {
    pattern = _.Pad('return') * _.V('ExprList'),
    compiler = function(exprlist)
      return 'return '..exprlist:join(',')
    end,
  },
}
