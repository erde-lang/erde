local _ENV = require('erde.parser._env').load()

-- -----------------------------------------------------------------------------
-- Local States
-- -----------------------------------------------------------------------------

local LOCAL_STATE_DIGIT = 0
local LOCAL_STATE_HEX = 1
local LOCAL_STATE_FLOAT = 2
local LOCAL_STATE_EXPONENT = 3
local LOCAL_STATE_EXPONENT_SIGN = 4

-- -----------------------------------------------------------------------------
-- Parse
--
-- TODO: negative numbers? Should be handled by operations?
-- -----------------------------------------------------------------------------

local function parse()
  if state ~= STATE_NUMBER then
    error('tried to parse in bad state: ' .. tostring(state))
  end

  local localState = LOCAL_STATE_DIGIT

  while bufValue do
    if localState == LOCAL_STATE_DIGIT then
      if Digit[bufValue] then
        growToken()
      elseif bufValue == '.' then
        localState = LOCAL_STATE_FLOAT
        growToken()
      elseif bufValue == 'x' or bufValue == 'X' then
        if #token == 0 then
          error('Must have at least one digit before hex x')
        elseif token[1] ~= '0' then
          error('hex numbers must start with 0')
        else
          localState = LOCAL_STATE_HEX
          growToken()
        end
      elseif bufValue == 'e' or bufValue == 'E' then
        if #token == 0 then
          error('Must have at least one digit before hex x')
        else
          localState = LOCAL_STATE_EXPONENT_SIGN
          growToken()
        end
      elseif #token == 0 then
        error('expected number, found ' .. string.char(bufValue))
      else
        break
      end
    elseif localState == LOCAL_STATE_HEX then
      if Hex[bufValue] then
        growToken()
      elseif not Hex[token[#token]] then
        error('malformed number, cannot end with "' .. token[#token] .. '"')
      else
        break
      end
    elseif localState == LOCAL_STATE_FLOAT then
      if Digit[bufValue] then
        growToken()
      elseif bufValue == 'e' or bufValue == 'E' then
        localState = LOCAL_STATE_EXPONENT_SIGN
        growToken()
      elseif not Digit[token[#token]] then
        error('malformed number, cannot end with "' .. token[#token] .. '"')
      else
        break
      end
    elseif localState == LOCAL_STATE_EXPONENT_SIGN then
      if bufValue == '+' or bufValue == '-' then
        growToken()
      end
      localState = LOCAL_STATE_EXPONENT
    elseif localState == LOCAL_STATE_EXPONENT then
      if Digit[bufValue] then
        growToken()
      elseif not Digit[token[#token]] then
        error('malformed number, cannot end with "' .. token[#token] .. '"')
      else
        break
      end
    else
      error('tried to parse in bad state: ' .. tostring(localState))
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
