local lib = require('erde.lib')

local PROMPT = '> '

return function()
  while true do
    io.write(PROMPT)
    local line = io.read()

    if line == nil then
      break
    elseif #line > 0 then
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
  end
end
