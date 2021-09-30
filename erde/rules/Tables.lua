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
  Destruct = {
    pattern = _.Product({
      _.Sum({
        _.Cc(1) * _.CsV('Name'),
        _.Cc(2) * _.V('Destructure'),
        _.Cc(3) * _.Product({
          _.P(':'),
          _.CsV('Name'),
          _.V('Destructure') ^ -1,
        }),
      }),
      (_.Pad('=') * _.CsV('Expr')) ^ -1,
    }),
    compiler = function(variant, expr1, expr2, expr3)
      if variant == 1 then
        return { name = expr1, default = expr2 }
      elseif variant == 2 then
        return { nested = expr1, default = expr2 }
      elseif variant == 3 then
        return {
          keyed = true,
          name = expr1,
          nested = expr2,
          default = expr3,
        }
      end
    end,
  },
  Destructure = {
    pattern = _.Product({
      _.Pad('{'),
      _.List(_.V('Destruct')),
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
