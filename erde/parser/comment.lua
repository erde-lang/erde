local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parser.comment()
  local capture = {}
  local node = {}

  if branchWord('---') then
    node.tag = TAG_LONG_COMMENT

    while true do
      if bufValue == '-' and branchWord('---') then
        break
      elseif bufValue == EOF then
        error('unterminated long comment')
      else
        consume(1, capture)
      end
    end
  elseif branchWord('--') then
    node.tag = TAG_SHORT_COMMENT

    while true do
      if bufValue == '\n' or bufValue == EOF then
        break
      else
        consume(1, capture)
      end
    end
  else
    error('invalid comment')
  end

  node.value = table.concat(capture)
  return node
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.comment(input)
  loadBuffer(input)
  local node = parser.comment()
  return node.value
end
