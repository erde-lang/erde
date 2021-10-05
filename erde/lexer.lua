local bytes = require('erde.bytes')
local utils = require('erde.utils')

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local buffer = {}
local char = 0
local bufIndex = 1

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function lexNumber()
  if not bytes.isNum(state.byte) then
    if not state.byte == bytes.Dot then
      return
    end
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return function (input)
  buffer = { string.byte(input, 1, #input) }
  bufIndex = 1
  bufValue = buffer[bufIndex]
end
