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
