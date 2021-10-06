local _ENV = require('erde.parser._env').load()

-- -----------------------------------------------------------------------------
-- Local States
-- -----------------------------------------------------------------------------

local LOCAL_STATE_SHORT = 'LOCAL_STATE_INNER'
local LOCAL_STATE_LONG = 'LOCAL_STATE_LONG_INNER'
local LOCAL_STATE_ESCAPE = 'LOCAL_STATE_ESCAPE'

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

local function parse()
  assert.state(STATE_STRING)
  local quote = bufValue

  local localState
  if bufValue == "'" or bufValue == '"' then
    localState = LOCAL_STATE_SHORT
  elseif bufValue == '`' then
    localState = LOCAL_STATE_LONG
  else
    error('Invalid quote: ' .. bufValue)
  end

  growToken()

  if localState == LOCAL_STATE_SHORT then
    while bufValue do
      if bufValue == quote then
        growToken()
        break
      elseif bufValue == '\\' then
        growToken(2)
      else
        growToken()
      end
    end
  elseif localState == LOCAL_STATE_LONG then
  else
    throw.badState(localState)
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
