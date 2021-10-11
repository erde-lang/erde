local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parser.string()
  local quote = bufValue

  if bufValue == "'" or bufValue == '"' then
    state = STATE_SHORT_STRING
  elseif bufValue == '`' then
    state = STATE_LONG_STRING
  else
    error('Expected quote (",\',`), found ' .. bufValue)
  end

  if state == STATE_SHORT_STRING then
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
  elseif state == STATE_LONG_STRING then
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
        consume()
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
    throw.badState()
  end
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.string(input)
  loadBuffer(input)
  return parser.string()
end
