local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parser.string()
  if bufValue == "'" or bufValue == '"' then
    local token = {}
    consume(1, token)

    while bufValue do
      if bufValue == token[1] then
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

    return { tag = TAG_SHORT_STRING, value = table.concat(token) }
  elseif bufValue == '`' then
    consume()
    local node = { tag = TAG_LONG_STRING }
    local token = {}

    while bufValue do
      if bufValue == '{' then
        consume()
        if #token > 0 then
          node[#node + 1] = table.concat(token)
          token = {}
        end
        node[#node + 1] = parser.expr()
        parser.space()
        if bufValue ~= '}' then
          error('unclosed interpolation')
        end
      elseif bufValue == '`' then
        consume(1)
        break
      elseif bufValue == '\\' then
        if ('{}`'):find(buffer[bufIndex + 1]) then
          consume()
          consume(1, token)
        else
          consume(2, token)
        end
      elseif bufValue == EOF then
        error('unterminated string')
      else
        consume(1, token)
      end
    end

    if #token > 0 then
      node[#node + 1] = table.concat(token)
    end

    return node
  else
    error('Expected quote (",\',`), found ' .. bufValue)
  end
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.string(input)
  loadBuffer(input)
  local node = parser.string()
  return node.tag == TAG_SHORT_STRING and node.value or node
end
