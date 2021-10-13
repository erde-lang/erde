local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parser.comment()
  if word(3) == '---' then
    consume(3)
    local capture = {}

    while true do
      if bufValue == '-' and word(3) == '---' then
        consume(3)
        break
      elseif bufValue == EOF then
        error('unterminated long comment')
      else
        consume(1, capture)
      end
    end

    return { tag = TAG_LONG_COMMENT, value = table.concat(capture) }
  elseif word(2) == '--' then
    consume(2)
    local capture = {}

    while true do
      if bufValue == '\n' or bufValue == EOF then
        break
      else
        consume(1, capture)
      end
    end

    return { tag = TAG_SHORT_COMMENT, value = table.concat(capture) }
  else
    error('invalid comment')
  end
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.comment(input)
  loadBuffer(input)
  local node = parser.comment()
  return node.value
end
