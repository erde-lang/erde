local C = require('erde.constants')
local lib = require('erde.lib')
local utils = require('erde.utils')

local PROMPT = '> '
local SUB_PROMPT = '>> '
local HAS_READLINE, RL = pcall(function() return require('readline') end)

if HAS_READLINE then
  RL.set_readline_name('erde')
  RL.set_options({
    keeplines = 1000,
    histfile = '~/.erde_history',
    completion = false,
    auto_add = false,
  })
end

local function readLine(prompt)
  local replLine
  if HAS_READLINE then
    replLine = RL.readline(prompt)
  else
    io.write(prompt)
    replLine = io.read()
  end

  if not replLine or replLine:match('^%s*$') then
    return
  end

  local sourceLines = {}
  local needsSubPrompt = false

  -- Check all lines from readline in case user is reusing a previous multiline command
  for _, line in pairs(utils.split(replLine, '\n')) do
    table.insert(sourceLines, (line:gsub('\\%s*$', '')))
  end

  return replLine, table.concat(sourceLines, '\n'), replLine:match('\\%s*$')
end

local function runRepl()
  print(('Erde %s on %s -- Copyright (C) 2021-2022 bsuth'):format(C.VERSION, _VERSION))
  print('Use trailing backslashes for multiline inputs.')

  if not HAS_READLINE then
    print('Install the `readline` Lua library to get support for arrow keys, keyboard shortcuts, history, etc.')
  end

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

    if HAS_READLINE then
      RL.add_history(replLine)
    end

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

return function()
  -- Protect runRepl so we don't show stacktraces when the user uses Control+c
  -- without readline.
  pcall(runRepl)
end
