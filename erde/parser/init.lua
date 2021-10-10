local _ENV = require('erde.parser.env').load()
require('erde.parser.space')
require('erde.parser.number')
require('erde.parser.string')
require('erde.parser.expr')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parser.parse()
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return parser
