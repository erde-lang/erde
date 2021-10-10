local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parser.number()
  local number = {}
  state = STATE_DIGIT

  while bufValue do
    if state == STATE_DIGIT then
      if Digit[bufValue] then
        consume(1, number)
      elseif bufValue == '.' then
        state = STATE_FLOAT
        consume(1, number)
      elseif bufValue == 'x' or bufValue == 'X' then
        if #number == 0 then
          error('Must have at least one digit before hex x')
        elseif number[1] ~= '0' then
          error('hex numbers must start with 0')
        else
          state = STATE_HEX
          consume(1, number)
        end
      elseif bufValue == 'e' or bufValue == 'E' then
        if #number == 0 then
          error('Must have at least one digit before hex x')
        else
          state = STATE_EXPONENT_SIGN
          consume(1, number)
        end
      elseif #number == 0 then
        -- TODO: abstract to env error handling, get word
        error('expected number, found ' .. string.char(bufValue))
      else
        break
      end
    elseif state == STATE_HEX then
      if Hex[bufValue] then
        consume(1, number)
      elseif not Hex[number[#number]] then
        error('malformed number, cannot end with "' .. number[#number] .. '"')
      else
        break
      end
    elseif state == STATE_FLOAT then
      if Digit[bufValue] then
        consume(1, number)
      elseif bufValue == 'e' or bufValue == 'E' then
        state = STATE_EXPONENT_SIGN
        consume(1, number)
      elseif not Digit[number[#number]] then
        error('malformed number, cannot end with "' .. number[#number] .. '"')
      else
        break
      end
    elseif state == STATE_EXPONENT_SIGN then
      if bufValue == '+' or bufValue == '-' then
        consume(1, number)
      end
      state = STATE_EXPONENT
    elseif state == STATE_EXPONENT then
      if Digit[bufValue] then
        consume(1, number)
      elseif not Digit[number[#number]] then
        error('malformed number, cannot end with "' .. number[#number] .. '"')
      else
        break
      end
    else
      throw.badState()
    end
  end

  return { tag = TAG_NUMBER, value = table.concat(number) }
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.number(input)
  loadBuffer(input)
  return parser.number().value
end
