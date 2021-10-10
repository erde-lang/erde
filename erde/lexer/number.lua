local _ENV = require('erde.lexer._env').load()

-- -----------------------------------------------------------------------------
-- Constants
-- -----------------------------------------------------------------------------

local LOCAL_STATE_DIGIT = 'LOCAL_STATE_DIGIT'
local LOCAL_STATE_HEX = 'LOCAL_STATE_HEX'
local LOCAL_STATE_FLOAT = 'LOCAL_STATE_FLOAT'
local LOCAL_STATE_EXPONENT = 'LOCAL_STATE_EXPONENT'
local LOCAL_STATE_EXPONENT_SIGN = 'LOCAL_STATE_EXPONENT_SIGN'

-- -----------------------------------------------------------------------------
-- Lex
-- -----------------------------------------------------------------------------

local function lex()
  assert.state(STATE_NUMBER)
  local localState = LOCAL_STATE_DIGIT
  local token = {}

  while bufValue do
    if localState == LOCAL_STATE_DIGIT then
      if Digit[bufValue] then
        consume(1, token)
      elseif bufValue == '.' then
        localState = LOCAL_STATE_FLOAT
        consume(1, token)
      elseif bufValue == 'x' or bufValue == 'X' then
        if #token == 0 then
          error('Must have at least one digit before hex x')
        elseif token[1] ~= '0' then
          error('hex numbers must start with 0')
        else
          localState = LOCAL_STATE_HEX
          consume(1, token)
        end
      elseif bufValue == 'e' or bufValue == 'E' then
        if #token == 0 then
          error('Must have at least one digit before hex x')
        else
          localState = LOCAL_STATE_EXPONENT_SIGN
          consume(1, token)
        end
      elseif #token == 0 then
        -- TODO: abstract to env error handling, get word
        error('expected number, found ' .. string.char(bufValue))
      else
        break
      end
    elseif localState == LOCAL_STATE_HEX then
      if Hex[bufValue] then
        consume(1, token)
      elseif not Hex[token[#token]] then
        error('malformed number, cannot end with "' .. token[#token] .. '"')
      else
        break
      end
    elseif localState == LOCAL_STATE_FLOAT then
      if Digit[bufValue] then
        consume(1, token)
      elseif bufValue == 'e' or bufValue == 'E' then
        localState = LOCAL_STATE_EXPONENT_SIGN
        consume(1, token)
      elseif not Digit[token[#token]] then
        error('malformed number, cannot end with "' .. token[#token] .. '"')
      else
        break
      end
    elseif localState == LOCAL_STATE_EXPONENT_SIGN then
      if bufValue == '+' or bufValue == '-' then
        consume(1, token)
      end
      localState = LOCAL_STATE_EXPONENT
    elseif localState == LOCAL_STATE_EXPONENT then
      if Digit[bufValue] then
        consume(1, token)
      elseif not Digit[token[#token]] then
        error('malformed number, cannot end with "' .. token[#token] .. '"')
      else
        break
      end
    else
      throw.badState(localState)
    end
  end

  return table.concat(token)
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  unit = function(input)
    loadBuffer(input)
    state = STATE_NUMBER
    return lex()
  end,
  lex = lex,
}
