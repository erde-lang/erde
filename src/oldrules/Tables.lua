require('env')()

return {
  StringTableKey = {
    parser = V('String'),
    compiler = template('[ %1 ]'),
  },
  ExprTableKey = {
    parser = PadC('[') * V('Expr') * PadC(']'),
    compiler = concat(' '),
  },
  MapTableField = {
    parser = Product({
      Sum({
        V('Name'),
        V('StringTableKey'),
        V('ExprTableKey'),
      }),
      Pad(':'),
      V('Expr'),
    }),
    compiler = template('%1 = %2'),
  },
  ShorthandTableField = {
    parser = Pad(P(':') * V('Name')),
    compiler = template('%1 = %1'),
  },
  TableField = {
    parser = V('ShorthandTableField') + V('MapTableField') + V('Expr'),
    compiler = echo,
  },
  Table = {
    parser = PadC('{') * (Csv(V('TableField'), true) + V('Space')) * PadC('}'),
    compiler = concat(),
  },
  DotIndex = {
    parser = V('Space') * C('.') * V('Name'),
    compiler = concat(),
  },
  BracketIndex = {
    parser = PadC('[') * V('Expr') * PadC(']'),
    compiler = concat(),
  },
  Index = {
    parser = Product({
      Pad('?') * Cc(true) + Cc(false),
      V('DotIndex') + V('BracketIndex'),
    }),
    compiler = map('optional', 'suffix'),
  },
  IndexChain = {
    parser = V('Index') ^ 1,
    compiler = pack,
  },
  Destruct = {
    parser = Product({
      C(':') + Cc(false),
      V('Name'),
      V('Destructure') + Cc(false),
      (Pad('=') * Demand(V('Expr'))) + Cc(false),
    }),
    compiler = map('keyed', 'name', 'nested', 'default'),
  },
  Destructure = {
    parser = Pad('{') * Csv(V('Destruct')) * Pad('}'),
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
