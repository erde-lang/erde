local parse = require('erde.parse')
local resolve = require('erde.resolve')
local compile = require('erde.compile')

return {
  tokenize = require('erde.tokenize'),
  parse = parse,
  resolve = resolve,
  compile = compile,
  run = function(text)
    local source = compile(text)

    local loader, err = loadstring(source)
    if type(loader) == 'function' then
      -- TODO: provide option to avoid pcall? Maybe disableSourceMap in manifest?
      local ok, result = pcall(function()
        return loader()
      end)

      if ok then
        return result
      else
        error('intercepted: ' .. result)
      end
    else
      error(table.concat({
        'Failed to load compiled Lua.',
        'Error: ' .. err,
        'Compiled Code: ' .. source,
      }, '\n'))
    end
  end,
}
