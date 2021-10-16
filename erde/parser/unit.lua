local _ENV = require('erde.parser.env').load()
require('erde.parser.rules')

return setmetatable({}, {
  __index = function(unit, key)
    unit[key] = function(input)
      loadBuffer(input)
      return parser[key]()
    end
    return unit[key]
  end,
})
