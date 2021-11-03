local ParserContext = require('erde.ParserContext')
local CompilerContext = require('erde.CompilerContext')
local rules = require('erde.rules')

-- Explicit import required for helper scripts
require('busted').expose('setup', function()
  parseCtx = ParserContext()
  compileCtx = CompilerContext()

  parse = {}
  compile = {}

  for name, rule in pairs(rules) do
    parse[name] = function(input)
      parseCtx:load(input)
      return rule.parse(parseCtx)
    end

    compile[name] = function(input)
      parseCtx:load(input)
      local node = rule.parse(parseCtx)
      return compileCtx:compile(node)
    end
  end
end)
