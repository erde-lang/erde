local grammar = require('syntax')

return {
  parse = function(subject)
    lpeg.setmaxstack(1000)

    local cap = {}
    local ast = grammar:match(subject, nil, cap)

    return ast, cap
  end,

  compile = function(ast)
    print(inspect(ast))
    return ''
  end,
}
