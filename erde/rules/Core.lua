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
  IndexChain = {
    pattern = (
      _.Product({
        _.Pad('?') * _.Cc(true) + _.Cc(false),
        _.Sum({
          _.Cc(1) * _.Pad('.') * _.CsV('Name'),
          _.Cc(2) * _.Pad('[') * _.CsV('Expr') * _.Pad(']'),
          _.Cc(3) * _.Pad('(') * _.List(_.CsV('Expr')) * _.Pad(')'),
          _.Cc(4) * _.Pad(':') * _.CsV('Name') * #_.Expect(_.Product({
            _.Pad('?') ^ -1,
            _.Pad('('),
            _.List(_.CsV('Expr')),
            _.Pad(')'),
          })),
        }),
      }) / _.map('optional', 'variant', 'value')
    ) ^ 0 / _.pack,
  },
  Id = {
    pattern = _.Sum({
      _.Pad('(') * _.CsV('Expr') * _.Pad(')'),
      _.CsV('Table'),
      _.CsV('Name'),
    }) * _.V('IndexChain'),
  },
}
