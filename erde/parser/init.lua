local _ENV = require('erde.parser.env').load()
require('erde.parser.rules')

return function()
  local block = parser.Block()

  if bufValue ~= EOF then
    throw.unexpected()
  end

  return block
end
