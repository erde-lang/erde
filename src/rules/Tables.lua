require('env')()

return {
  StringTableKey = {
    pattern = CsV('String'),
    compiler = '[ %1 ]',
  },
  MapTableField = {
    pattern = Product({
      Sum({
        CsV('Name'),
        CsV('StringTableKey'),
        Pad('[') * CsV('Expr') * Pad(']'),
      }),
      Pad(':'),
      CsV('Expr'),
    }),
    compiler = '%1 = %2',
  },
  ShorthandTableField = {
    pattern = Pad(P(':') * CsV('Name')),
    compiler = '%1 = %1',
  },
  TableField = {
    pattern = V('ShorthandTableField') + V('MapTableField') + V('Expr'),
    compiler = echo,
  },
  Table = {
    pattern = Product({
      Pad('{'),
      List(Sum({
        CsV('ShorthandTableField'),
        CsV('MapTableField'),
        CsV('Expr'),
      })),
      Pad('}')
    }),
    compiler = function(fields)
      return ('{ %s }'):format(fields:join(','))
    end,
  },
  DotIndex = {
    pattern = P('.') * V('Name'),
  },
  BracketIndex = {
    pattern = Pad('[') * V('Expr') * Pad(']'),
  },
  Index = {
    pattern = Product({
      V('Space'),
      Pad('?') * Cc(true) + Cc(false),
      CsV('DotIndex') + CsV('BracketIndex'),
    }),
    compiler = map('optional', 'suffix'),
  },
  IndexChain = {
    pattern = V('Index') ^ 1,
    compiler = pack,
  },
  Destruct = {
    pattern = Product({
      C(':') + Cc(false),
      V('Name'),
      V('Destructure') + Cc(false),
      (Pad('=') * Demand(V('Expr'))) + Cc(false),
    }),
    compiler = map('keyed', 'name', 'nested', 'default'),
  },
  Destructure = {
    pattern = Pad('{') * List(V('Destruct')) * Pad('}'),
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
