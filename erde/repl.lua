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
  if HAS_READLINE then
    return RL.readline(prompt)
  else
    io.write(prompt)
    return io.read()
  end
end

local function runRepl()
  print(('Erde %s on %s -- Copyright (C) 2021-2022 bsuth'):format(C.VERSION, _VERSION))
  print('Use trailing backslashes for multiline inputs.')

  if not HAS_READLINE then
    print('Install the `readline` Lua library to get support for arrow keys, keyboard shortcuts, history, etc.')
  end

  while true do
    local runOk, runResult
    local source = readLine(PROMPT)
    if not source then break end

    repeat
      -- Try input as an expression first! This way we can still print the value
      -- in the case that the expression is also a valid block (i.e. function calls).
      runOk, runResult = pcall(function()
        return lib.run('return ' .. source, 'stdin')
      end)

      if not runOk and runResult.type == 'compile' and not runResult.message:find('unexpected eof') then
        -- Try input as a block
        runOk, runResult = pcall(function()
          return lib.run(source, 'stdin')
        end)
      end
       
      if not runOk and runResult.type == 'compile' and runResult.message:find('unexpected eof') then
        repeat
          local subSource = readLine(SUB_PROMPT)
          source = source .. (subSource or '')
        until subSource
      end
    until runOk or runResult.type ~= 'compile' or not runResult.message:find('unexpected eof')

    if not runOk then
      print(runResult.stacktrace or runResult.message)
    elseif runResult ~= nil then
      print(runResult)
    end

    if HAS_READLINE then
      RL.add_history(source)
    end
  end
end

return function()
  -- Protect runRepl so we don't show stacktraces when the user uses Control+c
  -- without readline.
  pcall(runRepl)
end
