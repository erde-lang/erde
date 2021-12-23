local CompilerContext = require('erde.CompilerContext')
local ParserContext = require('erde.ParserContext')

local erde = {}
local parserCtx = ParserContext()
local compilerCtx = CompilerContext()

function erde.parse(input)
  -- TODO: remove node refs before returning (for example Continue nodes
  -- pointing back to the loopBlock)
  parserCtx:load(input)
  return parserCtx:Block({ isModuleBlock = true })
end

function erde.compile(ast)
  compilerCtx:reset()
  return compilerCtx:Block(ast)
end

function erde.run(input)
  local ast = erde.parse(input)
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
