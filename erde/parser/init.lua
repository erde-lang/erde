_ENV = require('erde.parser._env').load()

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function parseNext()
  bufIndex = bufIndex + 1
  bufValue = buffer[bufIndex]

  if bufValue == Newline then
    line = line + 1
    column = 1
  else
    column = column + 1
  end
end

local function parseNumber()
  while bufValue do
    if state == STATE_DIGIT then
      if bufValue == x or bufValue == X then
        if #token == 0 then
          error('Must have at least one digit before hex x')
        else
          state = STATE_HEX
        end
      elseif bufValue == Dot then
        state = STATE_FRACTION
      elseif not Digit[bufValue] then
        break
      end
    else
      break
    end

    token[#token + 1] = bufValue
    parseNext()
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  parse = function(input)
    buffer = { string.byte(input, 1, #input) }
    bufIndex = 1
    bufValue = buffer[bufIndex]
    parseNumber()

    local result = {}
    for key, value in pairs(token) do
      result[key] = string.char(value)
    end
    return table.concat(result)
  end,
}
