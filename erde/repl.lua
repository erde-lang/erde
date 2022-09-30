local RL = require('readline')
local C = require('erde.constants')
local lib = require('erde.lib')
local utils = require('erde.utils')

local PROMPT = '> '
local SUB_PROMPT = '>> '

RL.set_options({
  keeplines = 1000,
  histfile = '~/.erde_history',
  completion = false,
  auto_add = false,
})
RL.set_readline_name('erde')

local function readLine(prompt)
  local replLine = RL.readline(prompt)
  if not replLine or replLine:match('^%s*$') then return end

  local sourceLines = {}
  local needsSubPrompt = false

  -- Check all lines from readline in case user is reusing a previous multiline command
  for _, line in pairs(utils.split(replLine, '\n')) do
    table.insert(sourceLines, (line:gsub('\\%s*$', '')))
  end

  return replLine, table.concat(sourceLines, '\n'), replLine:match('\\%s*$')
end

return function()
  print('erde ' .. C.VERSION .. '  Copyright (C) 2021-2022 bsuth')
  print('Use trailing backslashes for multiline inputs.')

  while true do
    local replLine, sourceLine, needsSubPrompt = readLine(PROMPT)
    if not replLine then break end

    if needsSubPrompt then
      repeat
        local subReplLine, subSourceLine, needsSubPrompt = readLine(SUB_PROMPT)
        if not subReplLine then break end
        replLine = replLine .. '\n' .. subReplLine
        sourceLine = sourceLine .. '\n' .. subSourceLine
      until not needsSubPrompt
    end

    RL.add_history(replLine)

    -- Try expressions first! This way we can still print the value in the
    -- case that the expression is also a valid block (i.e. function calls).
    local exprOk, exprResult = pcall(function() return lib.run('return ' .. sourceLine, 'stdin') end)

    if exprOk then
      if exprResult ~= nil then
        print(exprResult)
      end
    elseif exprResult.type ~= 'compile' then
      print(exprResult.stacktrace or exprResult.message)
    else
      local blockOk, blockResult = pcall(function() return lib.run(sourceLine, 'stdin') end)

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
  end
end
