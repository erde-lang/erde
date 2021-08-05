require('env')()
local number = require('syntax.number')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

function merge(tables)
  local merged = {}

  for i, t in ipairs(tables) do
    for k, v in pairs(t) do
      merged[k] = v
    end
  end

  return merged
end

-- -----------------------------------------------------------------------------
-- Grammar
-- -----------------------------------------------------------------------------

local grammar = P(merge({
  number.grammar,
  {
    V('Lua'),
    Lua = V('Number'),
  },
}))

function parse(subject)
  lpeg.setmaxstack(1000)

  local cap = {}
  local ast = grammar:match(subject, nil, cap)

  return ast, cap
end

-- -----------------------------------------------------------------------------
-- Compiler
-- -----------------------------------------------------------------------------

local compiler = merge({
  number.compiler,
})

function compile(ast)
  local compiled = ''

  for i, v in ipairs(ast) do
    compiled = compiled .. compile(v)
  end

  if type(compiler[ast.tag]) == 'function' then
    compiled = compiled .. compiler[ast.tag](ast)
  end

  return compiled
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  parse = parse,
  compile = compile,
}
