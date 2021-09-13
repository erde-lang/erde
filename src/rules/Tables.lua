require('env')()
local Rule = require('rules.registry')

Rule('StringTableKey', {
  parser = V('String'),
  compiler = template('[ %1 ]'),
})

Rule('MapTableField ', {
  parser = (V('StringTableKey') + V('Name')) * Pad(':') * V('Expr'),
  compiler = template('%1 = %2'),
})

Rule('InlineTableField ', {
  parser = Pad(P(':') * V('Name')),
  compiler = template('%1 = %1'),
})

Rule('TableField  ', {
  parser = V('InlineTableField') + V('MapTableField') + V('Expr'),
  compiler = echo,
})

Rule('Table ', {
  parser = PadC('{') * (Csv(V('TableField'), true) + V('Space')) * PadC('}'),
  compiler = concat(),
})

Rule('DotIndex ', {
  parser = V('Space') * C('.') * V('Name'),
  compiler = concat(),
})

Rule('BracketIndex', {
  parser = PadC('[') * V('Expr') * PadC(']'),
  compiler = concat(),
})

Rule('Index ', {
  parser = Product({
    Pad('?') * Cc(true) + Cc(false),
    V('DotIndex') + V('BracketIndex'),
  }),
  compiler = map('optional', 'suffix'),
})

Rule('IndexChain ', {
  parser = V('Index') ^ 1,
  compiler = pack,
})

Rule('Destruct ', {
  parser = Product({
    C(':') + Cc(false),
    V('Name'),
    V('Destructure') + Cc(false),
    (Pad('=') * Demand(V('Expr'))) + Cc(false),
  }),
  compiler = map('keyed', 'name', 'nested', 'default'),
})

Rule('Destructure ', {
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
})
