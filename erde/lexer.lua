local bytes = require('erde.bytes')
local utils = require('erde.utils')
local sbyte = string.byte

local lexer = {}
local state = {
  pointer = 1,
  byte = 0,
  bytes = {},
}

local function lexCheckNumber()
  if state.byte ~= DOT then

  end
end

local function lexNumber()
end

function lexer.lex(input)
  state.bytes = { sbyte(input, 1, #input) }
  state.pointer = 1
  state.byte = state.bytes[1]
end

return lexer
