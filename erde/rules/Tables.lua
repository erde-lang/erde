local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  StringTableKey = {
    pattern = _.CsV('String'),
    compiler = '[ %1 ]',
  },
  MapTableField = {
    pattern = _.Product({
      _.Sum({
        _.CsV('Name'),
        _.CsV('StringTableKey'),
        _.Pad('[') * _.CsV('Expr') * _.Pad(']'),
      }),
      _.Pad(':'),
      _.CsV('Expr'),
    }),
    compiler = '%1 = %2',
  },
  ShorthandTableField = {
    pattern = _.Pad(_.P(':') * _.CsV('Name')),
    compiler = '%1 = %1',
  },
  Table = {
    pattern = _.Product({
      _.Pad('{'),
      _.List(_.Sum({
        _.CsV('ShorthandTableField'),
        _.CsV('MapTableField'),
        _.CsV('Expr'),
      })),
      _.Pad('}')
    }),
    compiler = function(fields)
      return ('{ %s }'):format(fields:join(','))
    end,
  },
  Destruct = {
    pattern = _.Product({
      _.C(':') + _.Cc(false),
      _.V('Name'),
      _.V('Destructure') + _.Cc(false),
      (_.Pad('=') * _.Expect(_.V('Expr'))) + _.Cc(false),
    }),
    compiler = _.map('keyed', 'name', 'nested', 'default'),
  },
  Destructure = {
    pattern = _.Pad('{') * _.List(_.V('Destruct')) * _.Pad('}'),
    compiler = function(...)
      local keycounter = 1
      return supertable({ ... }):each(function(destruct)
        if destruct.keyed then
          destruct.index = ('.%s'):format(destruct.name)
        else
          destruct.index = ('[%d]'):format(keycounter)
          keycounter = keycounter + 1
        end
      end)
    end,
  },
}
