_ENV = require('erde.parser._env').load()

-- -----------------------------------------------------------------------------
-- Parse
--
-- TODO: negative numbers? Should be handled by operations?
-- -----------------------------------------------------------------------------

local function parse()
  while bufValue do
    if state == STATE_NUMBER then
      if Digit[bufValue] then
        growToken()
      elseif bufValue == '.' then
        state = STATE_FLOAT
        growToken()
      elseif bufValue == 'x' or bufValue == 'X' then
        if #token == 0 then
          error('Must have at least one digit before hex x')
        elseif token[1] ~= '0' then
          error('hex numbers must start with 0')
        else
          state = STATE_HEX
          growToken()
        end
      elseif bufValue == 'e' or bufValue == 'E' then
        if #token == 0 then
          error('Must have at least one digit before hex x')
        else
          state = STATE_EXPONENT_SIGN
          growToken()
        end
      elseif #token == 0 then
        error('expected number, found ' .. string.char(bufValue))
      else
        break
      end
    elseif state == STATE_HEX then
      if Hex[bufValue] then
        growToken()
      elseif not Hex[token[#token]] then
        error('malformed number, cannot end with "' .. token[#token] .. '"')
      else
        break
      end
    elseif state == STATE_FLOAT then
      if Digit[bufValue] then
        growToken()
      elseif bufValue == 'e' or bufValue == 'E' then
        state = STATE_EXPONENT_SIGN
        growToken()
      elseif not Digit[token[#token]] then
        error('malformed number, cannot end with "' .. token[#token] .. '"')
      else
        break
      end
    elseif state == STATE_EXPONENT_SIGN then
      if bufValue == '+' or bufValue == '-' then
        growToken()
      end
      state = STATE_EXPONENT
    elseif state == STATE_EXPONENT then
      if Digit[bufValue] then
        growToken()
      elseif not Digit[token[#token]] then
        error('malformed number, cannot end with "' .. token[#token] .. '"')
      else
        break
      end
    else
      break
    end
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  unit = function(input)
    loadBuffer(input)
    state = STATE_NUMBER
    parse()
    return table.concat(token)
  end,
  parse = parse,
}
