local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parser.space(demand)
  if demand and not Whitespace[bufValue] then
    error('missing whitespace')
  end

  while Whitespace[bufValue] do
    next()
  end
end
