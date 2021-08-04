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
    Lua = V('Shebang') ^ -1 * V('Skip') * V('Chunk') * -1 + report_error(),
    Shebang = P('#') * (P(1) - P('\n')) ^ 0 * P('\n'),
    Chunk = V('Block'),
  },
}))

-- -----------------------------------------------------------------------------
-- Compiler
-- -----------------------------------------------------------------------------

local compiler = merge({
  number.grammar,
})

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  parse = function(subject)
    lpeg.setmaxstack(1000)

    local cap = {}
    local ast = grammar:match(subject, nil, cap)

    return ast, cap
  end,

  compile = function(ast)
    local compiled = ''

    for k, v in ast do
      if type(compiler[v.tag]) == 'function' then
        compiled = compiled .. compiler[v.tag](v)
      end
    end

    return compiled
  end,
}
