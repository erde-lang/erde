local Compiler = require('erde.Compiler')
local Parser = require('erde.Parser')

local erde = {}

function erde.parse(text)
  return Parser(text):Block()
end

function erde.compile(ast)
  return Compiler():compile(ast)
end

-- TODO: clean this up
function erde.run(text)
  local ast = erde.parse(text)
  local source = erde.compile(ast)

  local loader, err = (loadstring or load)(source)
  if type(loader) == 'function' then
    return loader()
  else
    error(table.concat({
      'Failed to load compiled Lua.',
      'Error: ' .. err,
      'Compiled Code: ' .. source,
    }, '\n'))
  end
end

return erde
