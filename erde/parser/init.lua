_ENV = require('erde.parser._env').load()

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local STATE_FREE = 0
local STATE_NUMBER = 1
local STATE_NUMBER_DECIMAL = 2
local STATE_STRING = 3

local state = STATE_NUMBER
local buffer = {}
local bufIndex = 1
local bufValue = 0

local line = 1
local column = 1

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function parseNext()
  bufIndex = bufIndex + 1
  bufValue = buffer[bufIndex]

  if bufValue == Newline then
    line = line + 1
    column = 1
  else
    column = column + 1
  end
end

local STATE_DECIMAL = 0

local function parseNumber()
  local state = STATE_NUMBER

  while bufValue do
    if bufValue == Dot then
      if state == STATE_DECIMAL then
        error('Found 2 dots')
      else
        state = STATE_DECIMAL
      end
    end

    if not Digits[bufValue] then
      error('expected digit')
    end
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  parse = function(input)
    buffer = { string.byte(input, 1, #input) }
    bufIndex = 1
    bufValue = buffer[bufIndex]
    parseNumber()
  end,
}
