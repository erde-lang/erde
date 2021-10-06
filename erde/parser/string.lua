local _ENV = require('erde.parser._env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

local function parse()
  if state ~= STATE_STRING then
    error('tried to parse in bad state: ' .. tostring(state))
  end

  while bufValue do
    if state == STATE_STRING then
      if bufValue == "'" then
      elseif bufValue == "'" then
      elseif bufValue == '`' then
      else
        error('expected string')
      end
    end
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  unit = function(input)
    loadBuffer(input)
    state = STATE_STRING
    parse()
    return table.concat(token)
  end,
  parse = parse,
}
