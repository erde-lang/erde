require('env')()

return {
  StringTableKey = {
    pattern = V('String'),
    compiler = '[ %1 ]',
  },
  MapTableField = {
    pattern = Product({
      Sum({
        CV('Name'),
        V('StringTableKey'),
        C(Pad('[') * V('Expr') * Pad(']')),
      }),
      Pad(':'),
      CV('Expr'),
    }),
    compiler = '%1 = %2',
  },
  ShorthandTableField = {
    pattern = Pad(P(':') * CV('Name')),
    compiler = '%1 = %1',
  },
  TableField = {
    pattern = V('ShorthandTableField') + V('MapTableField') + V('Expr'),
    compiler = echo,
  },
  Table = {
    pattern = PadC('{') * (Csv(V('TableField'), true) + V('Space')) * PadC('}'),
    compiler = concat(),
  },
  DotIndex = {
    pattern = V('Space') * C('.') * C(V('Name')),
    compiler = concat(),
  },
  BracketIndex = {
    pattern = PadC('[') * V('Expr') * PadC(']'),
    compiler = concat(),
  },
  Index = {
    pattern = Product({
      Pad('?') * Cc(true) + Cc(false),
      V('DotIndex') + V('BracketIndex'),
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
    pattern = Pad('{') * Csv(V('Destruct')) * Pad('}'),
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
