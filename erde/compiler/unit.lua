local compiler = require('erde.compiler')
local unitParser = require('erde.parser.unit')

return setmetatable({}, {
  __index = function(unit, key)
    unit[key] = function(input)
      local node = unitParser[key](input)
      return compiler[key](node)
    end
    return unit[key]
  end,
})
