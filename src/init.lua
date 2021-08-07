local grammar = require('grammar')
local syntax = require('syntax')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parse(subject)
  lpeg.setmaxstack(1000)

  local cap = {}
  local ast = grammar:match(subject, nil, cap)

  return ast, cap
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

local compiler = merge({
    Number = function(v)
      return v.value
    end,
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
