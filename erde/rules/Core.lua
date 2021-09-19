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
  },
  Keyword = {
    pattern = _.Pad(_.Sum({
      'local',
      'if',
      'elseif',
      'else',
      'false',
      'true',
      'nil',
      'return',
    })),
  },
  Name = {
    pattern = _.Product({
      -_.V('Keyword'),
      _.alpha + _.P('_'),
      (_.alnum + _.P('_')) ^ 0,
    }),
  },
  Id = {
    pattern = _.Sum({
      _.Pad('(') * _.CsV('Expr') * _.Pad(')') * _.V('IndexChain'),
      _.CsV('Name') * (_.V('IndexChain') + _.Cc(supertable())),
    }),
    compiler = _.indexchain(_.template('return %1')),
  },
  IdExpr = {
    pattern = _.V('Id'),
    compiler = _.indexchain(_.template('return %1')),
  },
}
