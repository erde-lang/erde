-- -----------------------------------------------------------------------------
-- Init
-- -----------------------------------------------------------------------------

local env = {
  -- Constants
  EOF = -1,

  -- Lookup Tables
  Alpha = {},
  Digit = {},
  Hex = {},
  Whitespace = {
    ['\n'] = true,
    ['\t'] = true,
    [' '] = true,
  },

  -- Public State
  buffer = {},
  bufIndex = 1,
  bufValue = 0,
  line = 1,
  column = 1,

  -- Parser
  parser = {},
}

for key, value in pairs(_G) do
  if env[key] == nil then
    env[key] = value
  end
end

local function load()
  if _VERSION:find('5.1') then
    setfenv(2, env)
  else
    return env
  end
end

local _ENV = load()

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function enumify(enum)
  for _, value in pairs(enum) do
    if env[value] ~= nil then
      error('Duplicate enum: ' .. value)
    end
    env[value] = value
  end
end

-- -----------------------------------------------------------------------------
-- Tags
-- -----------------------------------------------------------------------------

enumify({
  -- Comment
  'TAG_SHORT_COMMENT',
  'TAG_LONG_COMMENT',

  -- Var
  'TAG_LOCAL_VAR',
  'TAG_GLOBAL_VAR',

  -- Assignment
  'TAG_ASSIGNMENT',

  -- Number
  'TAG_NUMBER',

  -- Strings
  'TAG_SHORT_STRING',
  'TAG_LONG_STRING',

  -- Unops
  'TAG_NEG',
  'TAG_LEN',
  'TAG_NOT',
  'TAG_BNOT',

  -- Binops
  'TAG_PIPE',
  'TAG_TERNARY',
  'TAG_NC',
  'TAG_OR',
  'TAG_AND',
  'TAG_EQ',
  'TAG_NEQ',
  'TAG_LTE',
  'TAG_GTE',
  'TAG_LT',
  'TAG_GT',
  'TAG_BOR',
  'TAG_BXOR',
  'TAG_BAND',
  'TAG_LSHIFT',
  'TAG_RSHIFT',
  'TAG_CONCAT',
  'TAG_ADD',
  'TAG_SUB',
  'TAG_MULT',
  'TAG_DIV',
  'TAG_INTDIV',
  'TAG_MOD',
  'TAG_EXP',

  -- Logic Flows
  'TAG_IF_ELSE',
})

-- -----------------------------------------------------------------------------
-- Lookup Tables
-- -----------------------------------------------------------------------------

for byte = string.byte('0'), string.byte('9') do
  local char = string.char(byte)
  Digit[char] = true
  Hex[char] = true
end
for byte = string.byte('A'), string.byte('F') do
  local char = string.char(byte)
  Alpha[char] = true
  Hex[char] = true
end
for byte = string.byte('G'), string.byte('Z') do
  local char = string.char(byte)
  Alpha[char] = true
end
for byte = string.byte('a'), string.byte('f') do
  local char = string.char(byte)
  Alpha[char] = true
  Hex[char] = true
end
for byte = string.byte('g'), string.byte('z') do
  local char = string.char(byte)
  Alpha[char] = true
end

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

function env.loadBuffer(input)
  buffer = {}
  for i = 1, #input do
    buffer[i] = input:sub(i, i)
  end
  buffer[#buffer + 1] = EOF

  bufIndex = 1
  bufValue = buffer[bufIndex]
  line = 1
  column = 1
end

function env.consume(n, capture)
  n = n or 1

  if type(capture) == 'table' then
    for i = 0, n - 1 do
      capture[#capture + 1] = buffer[bufIndex + i]
    end
  end

  for i = 1, n do
    bufIndex = bufIndex + 1
    bufValue = buffer[bufIndex]

    if bufValue == Newline then
      line = line + 1
      column = 1
    else
      column = column + 1
    end
  end
end

function env.peek(n)
  local word = { bufValue }

  for i = 1, n - 1 do
    local char = buffer[bufIndex + i]
    if not char or char == EOF then
      break
    end
    word[#word + 1] = char
  end

  return table.concat(word)
end

function env.stream(lookupTable, capture, demand)
  if demand and not lookupTable[bufValue] then
    error('unexpected value')
  end

  while lookupTable[bufValue] do
    consume(1, capture)
  end
end

function env.branchChar(char, capture)
  if #char > 1 and char:find(bufValue) or bufValue == char then
    consume(1, capture)
    return true
  else
    return false
  end
end

function env.branchStr(str, capture)
  if peek(#str) == str then
    consume(#str, capture)
    return true
  else
    return false
  end
end

function env.branchWord(word, capture)
  parser.space()
  local trailingChar = buffer[bufIndex + #word]
  if Alpha[trailingChar] or Digit[trailingChar] then
    return false
  elseif branchStr(word, capture) then
    parser.space()
    return true
  end
end

-- -----------------------------------------------------------------------------
-- Error Handling
-- -----------------------------------------------------------------------------

env.assert = {}

env.throw = {}

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return { load = load }
