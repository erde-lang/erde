require('env')()

return {
  StringTableKey = {
    pattern = V('String'),
    oldcompiler = template('[ %1 ]'),
  },
  MapTableField = {
    pattern = Product({
      V('Name') + V('StringTableKey'),
      Pad(':'),
      V('Expr'),
    }),
    oldcompiler = template('%1 = %2'),
  },
  ShorthandTableField = {
    pattern = Pad(P(':') * V('Name')),
    oldcompiler = template('%1 = %1'),
  },
  TableField = {
    pattern = V('ShorthandTableField') + V('MapTableField') + V('Expr'),
    oldcompiler = echo,
  },
  Table = {
    pattern = PadC('{') * (Csv(V('TableField'), true) + V('Space')) * PadC('}'),
    oldcompiler = concat(),
  },
  DotIndex = {
    pattern = V('Space') * C('.') * V('Name'),
    oldcompiler = concat(),
  },
  BracketIndex = {
    pattern = PadC('[') * V('Expr') * PadC(']'),
    oldcompiler = concat(),
  },
  Index = {
    pattern = Product({
      Pad('?') * Cc(true) + Cc(false),
      V('DotIndex') + V('BracketIndex'),
    }),
    oldcompiler = map('optional', 'suffix'),
  },
  IndexChain = {
    pattern = V('Index') ^ 1,
    oldcompiler = pack,
  },
  Destruct = {
    pattern = Product({
      C(':') + Cc(false),
      V('Name'),
      V('Destructure') + Cc(false),
      (Pad('=') * Demand(V('Expr'))) + Cc(false),
    }),
    oldcompiler = map('keyed', 'name', 'nested', 'default'),
  },
  Destructure = {
    pattern = Pad('{') * Csv(V('Destruct')) * Pad('}'),
    oldcompiler = function(...)
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
