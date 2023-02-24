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

local function readline(prompt)
  if HAS_READLINE then
    return RL.readline(prompt)
  else
    io.write(prompt)
    return io.read()
  end
end

local function repl()
  print(('Erde %s on %s -- Copyright (C) 2021-2022 bsuth'):format(C.VERSION, _VERSION))

  if not HAS_READLINE then
    print('Install the `readline` Lua library to get support for arrow keys, keyboard shortcuts, history, etc.')
  end

  while true do
    local ok, result
    local source = readline(PROMPT)

    -- Readline returns the string '(null)' on <C-d> for some reason.
    if not source or (HAS_READLINE and source == '(null)') then
      break
    end

    repeat
      -- Try input as an expression first! This way we can still print the value
      -- in the case that the expression is also a valid block (i.e. function calls).
      ok, result = pcall(function()
        return lib.run('return ' .. source, 'stdin')
      end)

      if not ok and result.type == 'compile' and not result.message:find('unexpected eof') then
        -- Try input as a block
        ok, result = pcall(function()
          return lib.run(source, 'stdin')
        end)
      end

      if not ok and result.type == 'compile' and result.message:find('unexpected eof') then
        repeat
          local subsource = readline(SUB_PROMPT)
          source = source .. (subsource or '')
        until subsource
      end
    until ok or result.type ~= 'compile' or not result.message:find('unexpected eof')

    if not ok then
      print(result.stacktrace or result.message)
    elseif result ~= nil then
      print(result)
    end

    if HAS_READLINE and utils.trim(source) ~= '' then
      RL.add_history(source)
    end
  end
end

return function()
  -- Protect repl so we don't show stacktraces when the user uses Control+c
  -- without readline.
  pcall(repl)
  if HAS_READLINE then
    RL.save_history()
  end
end
