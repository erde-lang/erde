local busted = require('busted')
local ParserContext = require('erde.ParserContext')
local rules = require('erde.rules')

busted.expose('setup', function()
  ctx = ParserContext()

  parse = {}
  compile = {}

  for key, value in pairs(rules) do
    parse[key] = function(input)
      ctx:load(input)
      return value.parse(ctx)
    end

    compile[key] = function(input)
      ctx:load(input)
      local node = value.parse(ctx)
      return value.compile(node)
    end
  end
end)
