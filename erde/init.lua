local parse = require('erde.parse')
local compile = require('erde.compile')

return {
  tokenize = require('erde.tokenize'),
  parse = parse,
  compile = compile,

  -- TODO: clean this up
  run = function(text)
    local ast = parse(text)
    local source = compile(ast)

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
  end,
}
