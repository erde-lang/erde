local lpeg = require('lpeg')
local supertable = require('supertable')

return setmetatable({
  parser = supertable({ lpeg.V('Block') }),
  compiler = supertable(),
}, {
  __call = function(self, name, rule)
    self.parser:merge({ [name] = rule.parser })
    self.compiler:merge({ [name] = rule.compiler })
  end,
})
