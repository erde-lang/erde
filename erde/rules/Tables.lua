local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  KeyValuePair = {
    pattern = 
    _.Product({
      _.Sum({
        _.Cc(1) * _.CsV('Name'),
        _.Cc(2) * _.CsV('String'),
        _.Cc(3) * _.Pad('[') * _.CsV('Expr') * _.Pad(']'),
      }),
      _.Pad(':'),
      _.CsV('Expr'),
    }),
    compiler = function(variant, key, value)
      return variant == 1 and key..' = '..value or '['..key..'] = '..value
    end,
  },
  Table = {
    pattern = _.Product({
      _.Pad('{'),
      _.List(
        _.Sum({
          _.Cc(1) * _.CsV('KeyValuePair'),
          _.Cc(2) * _.Pad(_.P(':') * _.CsV('Name')),
          _.Cc(3) * _.CsV('Expr'),
        }) / _.map('variant', 'capture')
      ),
      _.Pad('}')
    }),
    compiler = function(fields)
      local joinedFields = fields:map(function(field)
        return field.variant == 2
          and field.capture..' = '..field.capture
          or field.capture
      end):join(',')
      return '{'..joinedFields..'}'
    end,
  },
  Destructure = {
    pattern = _.Product({
      _.Pad('{'),
      _.List(
        _.Product({
          _.P(':') * _.Cc(true) + _.Cc(false),
          _.CsV('Name'),
          _.V('Destructure') + _.Cc(false),
          _.Pad('=') * _.CsV('Expr') + _.Cc(false),
        }) / _.map('keyed', 'name', 'nested', 'default')
      ),
      _.Pad('}'),
    }),
    compiler = function(destructure)
      local keyCounter = 1
      return destructure:each(function(destruct)
        if destruct.keyed then
          destruct.index = ('.%s'):format(destruct.name)
        else
          destruct.index = ('[%d]'):format(keyCounter)
          keyCounter = keyCounter + 1
        end
      end)
    end,
  },
}
