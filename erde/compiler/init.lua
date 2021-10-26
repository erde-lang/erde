local parse = require('erde.parser')

-- -----------------------------------------------------------------------------
-- Compiler
-- -----------------------------------------------------------------------------

local compiler = {}

function compiler.compile(input)
  return compiler.Block(parse(input))
end

local function compileNode(node)
  local nodeCompiler = compiler[node.rule]
  return type(nodeCompiler) == 'function' and nodeCompiler(node) or ''
end

local function format(str, values)
  for i, value in ipairs(values) do
    str = str:gsub(i .. '%', tostring(value))
  end

  return str
end

-- -----------------------------------------------------------------------------
-- Rule: ArrowFunction
-- -----------------------------------------------------------------------------

function compiler.ArrowFunction(node)
  local params = compile(node.params)
  if node.variant == 'fat' then
    table.insert(params.names, 1, 'self')
  end

  local body
  if node.body then
    body = compile(node.body)
  else
    local returns = {}

    for i, value in ipairs(node.returns) do
      returns[i] = compile(value)
    end

    body = 'return ' .. table.concat(returns, ',')
  end

  return ('function(%s)\n%s\n%s\nend'):format(
    table.concat(params.names, ','),
    params.prebody,
    body
  )
end

-- -----------------------------------------------------------------------------
-- Rule: Assignment
-- -----------------------------------------------------------------------------

function compiler.Assignment(node)
  local compiled = { node.name, '=', nil, nil, nil }

  if node.op then
    compiled[3] = node.name
    compiled[4] = node.op
    compiled[5] = compile(node.expr)
  else
    compiled[3] = compile(node.expr)
  end

  return table.concat(compiled, ' ')
end

-- -----------------------------------------------------------------------------
-- Rule: Block
-- -----------------------------------------------------------------------------

function compiler.Block(node)
  local compiled = {}

  for _, statement in ipairs(node) do
    compiled[#compiled + 1] = compileNode(statement)
  end

  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Comment
-- -----------------------------------------------------------------------------

function compiler.Comment(node)
  return nil
end

-- -----------------------------------------------------------------------------
-- Rule: Destructure
-- TODO
-- -----------------------------------------------------------------------------

function compiler.Destructure(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: DoBlock
-- -----------------------------------------------------------------------------

function compiler.DoBlock(node)
  return (node.hasReturn and 'function()\n%s\nend' or 'do\n%s\nend'):format(
    compile(node.body)
  )
end

-- -----------------------------------------------------------------------------
-- Rule: Expr
-- TODO
-- -----------------------------------------------------------------------------

function compiler.Expr(minPrec)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: ForLoop
-- -----------------------------------------------------------------------------

function compiler.ForLoop(node)
  if node.variant == 'numeric' then
    return ('for %s=%s,%s,%s do\n%s\nend'):format(
      node.name,
      compile(node.var),
      compile(node.limit),
      node.step and compile(node.step) or '1',
      compile(node.body)
    )
  else
    local exprList = {}
    for i, expr in ipairs(node.exprList) do
      exprList[i] = compile(expr)
    end

    return ('for %s in %s do\n%s\nend'):format(
      table.concat(node.nameList, ','),
      table.concat(exprList, ','),
      compile(node.body)
    )
  end
end

-- -----------------------------------------------------------------------------
-- Rule: Function
-- -----------------------------------------------------------------------------

function compiler.Function(node)
  local params = compile(node.params)

  local methodName
  if node.isMethod then
    methodName = table.remove(node.names)
  end

  return ('%s function %s%s(%s)\n%s\n%s\nend'):format(
    node.variant == 'local' and 'local' or '',
    table.concat(node.names, '.'),
    methodName and ':' .. methodName or '',
    table.concat(compile(params.names), ','),
    params.prebody,
    compile(node.body)
  )
end

-- -----------------------------------------------------------------------------
-- Rule: IfElse
-- -----------------------------------------------------------------------------

function compiler.IfElse(node)
  local compiled = {
    'if ' .. compile(elseifNode.cond) .. ' then',
    compile(node.body),
  }

  for _, elseifNode in ipairs(node.elseifNodes) do
    compiled[#compiled + 1] = 'elseif ' .. compile(elseifNode.cond) .. ' then'
    compiled[#compiled + 1] = compile(node.body)
  end

  if node.elseNode then
    compiled[#compiled + 1] = 'else'
    compiled[#compiled + 1] = compile(node.body)
  end

  compiled[#compiled + 1] = 'end'
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Name
-- -----------------------------------------------------------------------------

function compiler.Name(node)
  return node.value
end

-- -----------------------------------------------------------------------------
-- Rule: Number
-- -----------------------------------------------------------------------------

function compiler.Number(node)
  return node.value
end

-- -----------------------------------------------------------------------------
-- Rule: OptChain
-- TODO
-- -----------------------------------------------------------------------------

function compiler.OptChain(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Params
-- TODO
-- -----------------------------------------------------------------------------

function compiler.Params(node)
  local names = {}
  local prebody = {}

  for i, param in ipairs(node) do
    local name
    if param.value.rule == 'Name' then
      name = param.value.value
    else
      -- TODO: destructure
    end

    if param.default then
      prebody[#prebody + 1] = 'if ' .. name .. ' == nil then'
      prebody[#prebody + 1] = compile(param.default)
      prebody[#prebody + 1] = 'end'
    end

    names[#names + 1] = name
  end

  return { names = names, prebody = table.concat(prebody, '\n') }
end

-- -----------------------------------------------------------------------------
-- Rule: RepeatUntil
-- -----------------------------------------------------------------------------

function compiler.RepeatUntil(node)
  return ('repeat\n%s\nuntil (%s)'):format(
    compile(node.body),
    compile(node.cond)
  )
end

-- -----------------------------------------------------------------------------
-- Rule: Return
-- -----------------------------------------------------------------------------

function compiler.Return(node)
  return 'return ' .. node.value
end

-- -----------------------------------------------------------------------------
-- Rule: String
-- -----------------------------------------------------------------------------

function compiler.String(node)
  if node.variant == 'short' then
    return node.value
  else
    local eqStr = '='
    local content = {}

    for _, capture in ipairs(node) do
      if type(capture) == 'string' and capture:find(eqStr) then
        eqStr = ('='):rep(#eqStr + 1)
      end
    end

    for _, capture in ipairs(node) do
      if type(capture) == 'string' then
        content[#content + 1] = capture
      else
        content[#content + 1] = (']%s]..tostring(%s)..[%s['):format(
          eqStr,
          compileNode(capture),
          eqStr
        )
      end
    end

    return ('[%s[%s]%s]'):format(eqStr, table.concat(content), eqStr)
  end
end

-- -----------------------------------------------------------------------------
-- Rule: Table
-- -----------------------------------------------------------------------------

function compiler.Table(node)
  local compiled = { '{' }

  for i, field in ipairs(node) do
    if field.variant == 'arrayKey' then
      compiled[#compiled + 1] = format('%1,', compile(field.value))
    elseif field.variant == 'inlineKey' then
      compiled[#compiled + 1] = format('%1 = %1,', field.key)
    elseif field.variant == 'exprKey' then
      compiled[#compiled + 1] = format(
        '[%1] = %2,',
        field.key,
        compile(field.value)
      )
    elseif variant == 'nameKey' then
      compiled[#compiled + 1] = format(
        '%1 = %2,',
        field.key,
        compile(field.value)
      )
    elseif variant == 'stringKey' then
      compiled[#compiled + 1] = format(
        '[%1] = %2,',
        compile(field.key),
        compile(field.value)
      )
    end
  end

  compiled[#compiled + 1] = '}'
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Terminal
-- -----------------------------------------------------------------------------

function compiler.Terminal(node)
  return node.value
end

-- -----------------------------------------------------------------------------
-- Rule: Var
-- -----------------------------------------------------------------------------

function compiler.Var(node)
  local compiled = {}

  if node.variant == 'local' then
    compiled[#compiled + 1] = 'local'
  end

  compiled[#compiled + 1] = node.name

  if node.initValue then
    compiled[#compiled + 1] = '='
    compiled[#compiled + 1] = compile(node.initValue)
  end

  return table.concat(compiled, ' ')
end

-- -----------------------------------------------------------------------------
-- Rule: WhileLoop
-- -----------------------------------------------------------------------------

function compiler.WhileLoop(node)
  return ('while %s do\n%s\nend'):format(compile(node.cond), compile(node.body))
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return compiler
