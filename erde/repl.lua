local RL = require('readline')
local C = require('erde.constants')
local lib = require('erde.lib')

local PROMPT = '> '
local SUB_PROMPT = '>> '

-- TODO support strings
local SURROUND_OPENING_CHARS = { ['('] = ')', ['{'] = '}', ['['] = ']' }
local SURROUND_CLOSING_CHARS = { [')'] = '(', ['}'] = '{', [']'] = '[' }

RL.set_readline_name('erde')
RL.set_options({
  keeplines = 1000,
  histfile = '~/.erde_history',
  completion = false,
  auto_add = false,
})

local function updateSurroundCounters(line, surroundCounters)
  for i = 1, #line do
    local char = line:sub(i, i)
    if SURROUND_OPENING_CHARS[char] ~= nil then
      surroundCounters[char] = surroundCounters[char] + 1
    elseif SURROUND_CLOSING_CHARS[char] ~= nil then
      local openingChar = SURROUND_CLOSING_CHARS[char]
      surroundCounters[openingChar] = math.max(0, surroundCounters[openingChar] - 1)
    end
  end

  for char, counter in pairs(surroundCounters) do
    if counter > 0 then
      return true
    end
  end

  return false
end

local function getLine()
  local line = RL.readline(PROMPT)

  if line and #line > 0 then
    local surroundCounters = { ['('] = 0, ['{'] = 0, ['['] = 0 }
    local needsSubPrompt = updateSurroundCounters(line, surroundCounters)

    if needsSubPrompt then
      repeat
        local subLine = RL.readline(SUB_PROMPT)
        needsSubPrompt = updateSurroundCounters(subLine, surroundCounters)
        line = line .. '\n' .. subLine
      until not needsSubPrompt or not subLine
    end

    RL.add_history(line)
    return line
  end
end

return function()
  print('erde ' .. C.VERSION .. '  Copyright (C) 2021-2022 bsuth')
  local line = getLine()

  while line do
    -- Try expressions first! This way we can still print the value in the
    -- case that the expression is also a valid block (i.e. function calls).
    local exprOk, exprResult = pcall(function() return lib.run('return ' .. line, 'stdin') end)
    
    if exprOk then
      if exprResult ~= nil then
        print(exprResult)
      end
    elseif exprResult.type ~= 'compile' then
      print(exprResult.stacktrace)
    else
      local blockOk, blockResult = pcall(function() return lib.run(line, 'stdin') end)
      
      if blockOk then
        if blockResult ~= nil then
          print(blockResult)
        end
      elseif blockResult.type ~= 'compile' then
        print(blockResult.stacktrace)
      else
        print('invalid syntax')
        print('expr: ' .. tostring(exprResult))
        print('block: ' .. tostring(blockResult))
      end
    end

    line = getLine()
  end
end
