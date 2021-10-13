local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parser.string()
  if bufValue == "'" or bufValue == '"' then
    local capture = {}
    consume(1, capture)

    while true do
      if bufValue == capture[1] then
        consume(1, capture)
        break
      elseif bufValue == '\n' or bufValue == EOF then
        error('unterminated string')
      else
        consume(1, capture)
      end
    end

    return { tag = TAG_SHORT_STRING, value = table.concat(capture) }
  elseif branchChar('`') then
    local node = { tag = TAG_LONG_STRING }
    local capture = {}

    while true do
      if branchChar('{') then
        if #capture > 0 then
          node[#node + 1] = table.concat(capture)
          capture = {}
        end

        node[#node + 1] = pad(parser.expr)
        if not branchChar('}') then
          error('unclosed interpolation')
        end
      elseif branchChar('`') then
        break
      elseif bufValue == '\\' then
        if ('{}`'):find(buffer[bufIndex + 1]) then
          consume()
          consume(1, capture)
        else
          consume(2, capture)
        end
      elseif bufValue == EOF then
        error('unterminated string')
      else
        consume(1, capture)
      end
    end

    if #capture > 0 then
      node[#node + 1] = table.concat(capture)
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
