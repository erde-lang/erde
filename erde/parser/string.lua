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
    error('Expected quote (",\',`), found ' .. bufValue)
  end

  if localState == LOCAL_STATE_SHORT then
    local token = {}
    consume(1, token)

    while bufValue do
      if Alpha[bufValue] or Digit[bufValue] then -- most common case
        consume(1, token)
      elseif bufValue == quote then
        consume(1, token)
        break
      elseif bufValue == '\\' then
        consume(2, token)
      elseif bufValue == '\n' or bufValue == EOF then
        error('unterminated string')
      else
        consume(1, token)
      end
    end

    return table.concat(token)
  elseif localState == LOCAL_STATE_LONG then
    local node = { tag = TAG_LONG_STRING }
    local token = {}

    while bufValue do
      if Alpha[bufValue] or Digit[bufValue] then -- most common case
        consume(1, token)
      elseif bufValue == '{' then
        -- TODO: interpolation
      elseif bufValue == quote then
        node[#node + 1] = table.concat(token)
        consume(1, token)
        break
      elseif bufValue == '\\' then
        next()
        if bufValue ~= '{' and bufValue ~= '`' then
          token[#token + 1] = '\\'
        end
        consume(1, token)
      elseif bufValue == EOF then
        error('unterminated string')
      else
        consume(1, token)
      end
    end
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
    return parse()
  end,
  parse = parse,
}
