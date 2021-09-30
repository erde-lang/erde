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
    pattern = function()
      local OptDestructure = _.Product({
        _.Pad('?') * _.Cc(true) + _.Cc(false),
        _.V('Destructure'),
      })

      return _.Product({
        _.Sum({
          _.Cc(1) * _.CsV('Name'),
          _.Cc(2) * OptDestructure,
          _.Cc(3) * _.Product({
            _.P(':'),
            _.CsV('Name'),
            OptDestructure ^ -1,
          }),
        }),
        (_.Pad('=') * _.CsV('Expr')) ^ -1,
      })
    end,
    compiler = function(variant, c1, c2, c3, c4)
      if variant == 1 then
        return { name = c1, default = c2 }
      elseif variant == 2 then
        return { opt = c1, nested = c2, default = c3 }
      elseif variant == 3 then
        local destruct = { keyed = true, name = c1 }
        if type(c2) == 'boolean' then
          destruct.opt = c2
          destruct.nested = c3
          destruct.default = c4
        else
          destruct.opt = c2
        end
        return destruct
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
