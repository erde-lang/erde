local RL = require('readline')
local lib = require('erde.lib')

local PROMPT = '> '

RL.set_readline_name('erde')
RL.set_options({
  keeplines = 1000,
  histfile = '~/.erde_history',
  completion = false,
  auto_add = false,
})

return function()
  repeat
    local line = RL.readline(PROMPT)
    if line and #line > 0 then
      RL.add_history(line)

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
    end
  until not line
end
