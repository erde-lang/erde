local parse = require('erde.parser')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local tmpNameCounter = 1
local function newTmpName()
  tmpNameCounter = tmpNameCounter + 1
  return ('__ERDE_TMP_%d__'):format(tmpNameCounter)
end

local function format(str, ...)
  for i, value in ipairs({ ... }) do
    str = str:gsub(i .. '%', tostring(value))
  end

  return str
end

-- -----------------------------------------------------------------------------
-- Compiler
-- -----------------------------------------------------------------------------

local compiler = {
  compile = function(input)
    return compile(parse(input))
  end,
}

local function compile(node)
  local nodeCompiler = compiler[node.rule]
  if type(nodeCompiler) == 'function' then
    if node.parens then
      return format('(%1)', nodeCompiler(node))
    else
      return nodeCompiler(node)
    end
  else
    print(require('inspect')(node))
    error('No node compiler for')
  end
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
  local compileParts = { node.name, '=', nil, nil, nil }

  if node.op then
    compileParts[3] = node.name
    compileParts[4] = node.op
    compileParts[5] = compile(node.expr)
  else
    compileParts[3] = compile(node.expr)
  end

  return table.concat(compileParts, ' ')
end

-- -----------------------------------------------------------------------------
-- Rule: Block
-- -----------------------------------------------------------------------------

function compiler.Block(node)
  local compileParts = {}

  for _, statement in ipairs(node) do
    compileParts[#compileParts + 1] = compile(statement)
  end

  return table.concat(compileParts, '\n')
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
  local compileParts = {}
  return table.concat(compileParts, '\n')
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

function compiler.Expr(node)
  local op = node.op

  if node.variant == 'unop' then
    local operand = compile(node[1])

    local function compileUnop(token)
      return table.concat({ token, operand }, ' ')
    end

    if op.tag == 'bnot' then
      return _VERSION:find('5.[34]') and compileUnop('~')
        or format('require("bit").bnot(%1)', operand)
    elseif op.tag == 'not' then
      return compileUnop('not')
    else
      return op.token .. operand
    end
  elseif op.variant == 'binop' then
    local lhs = compile(node[1])
    local rhs = compile(node[2])

    local function compileBinop(token)
      return table.concat({ lhs, token, rhs }, ' ')
    end

    if op.tag == 'pipe' then
      -- TODO: pipe
    elseif op.tag == 'ternary' then
      return format(
        table.concat({
          '(function()',
          'if %1 then',
          'return %2',
          'else',
          'return %3',
          'end',
          'end)()',
        }, '\n'),
        lhs,
        rhs,
        compile(node[3])
      )
    elseif op.tag == 'nc' then
      return format(
        table.concat({
          '(function()',
          'local %1 = %2',
          'if %1 ~= nil then',
          'return %1',
          'else',
          'return %3',
          'end',
          'end)()',
        }, '\n'),
        newTmpName(),
        lhs,
        rhs
      )
    elseif op.tag == 'or' then
      return compileBinop('or')
    elseif op.tag == 'and' then
      return compileBinop('and')
    elseif op.tag == 'bor' then
      return format('require("bit").bor(%1, %2)', lhs, rhs)
    elseif op.tag == 'bxor' then
      return format('require("bit").bxor(%1, %2)', lhs, rhs)
    elseif op.tag == 'band' then
      return format('require("bit").band(%1, %2)', lhs, rhs)
    elseif op.tag == 'lshift' then
      return format('require("bit").lshift(%1, %2)', lhs, rhs)
    elseif op.tag == 'rshift' then
      return format('require("bit").rshift(%1, %2)', lhs, rhs)
    elseif op.tag == 'intdiv' then
      return _VERSION:find('5.[34]') and compileBinop('//')
        or format('math.floor(%s / %s)', lhs, rhs)
    else
      return compileBinop(op.token)
    end
  end
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
  local compileParts = {
    format('if %1 then', compile(elseifNode.cond)),
    compile(node.body),
  }

  for _, elseifNode in ipairs(node.elseifNodes) do
    compileParts[#compileParts + 1] = format(
      'elseif %1 then',
      compile(elseifNode.cond)
    )
    compileParts[#compileParts + 1] = compile(node.body)
  end

  if node.elseNode then
    compileParts[#compileParts + 1] = 'else'
    compileParts[#compileParts + 1] = compile(node.body)
  end

  compileParts[#compileParts + 1] = 'end'
  return table.concat(compileParts, '\n')
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
  local compileParts = {}
  return table.concat(compileParts, '\n')
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
          compile(capture),
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
  local compileParts = { '{' }

  for i, field in ipairs(node) do
    if field.variant == 'arrayKey' then
      compileParts[#compileParts + 1] = format('%1,', compile(field.value))
    elseif field.variant == 'inlineKey' then
      compileParts[#compileParts + 1] = format('%1 = %1,', field.key)
    elseif field.variant == 'exprKey' then
      compileParts[#compileParts + 1] = format(
        '[%1] = %2,',
        field.key,
        compile(field.value)
      )
    elseif variant == 'nameKey' then
      compileParts[#compileParts + 1] = format(
        '%1 = %2,',
        field.key,
        compile(field.value)
      )
    elseif variant == 'stringKey' then
      compileParts[#compileParts + 1] = format(
        '[%1] = %2,',
        compile(field.key),
        compile(field.value)
      )
    end
  end

  compileParts[#compileParts + 1] = '}'
  return table.concat(compileParts, '\n')
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
  local compileParts = {}

  if node.variant == 'local' then
    compileParts[#compileParts + 1] = 'local'
  end

  compileParts[#compileParts + 1] = node.name

  if node.initValue then
    compileParts[#compileParts + 1] = '='
    compileParts[#compileParts + 1] = compile(node.initValue)
  end

  return table.concat(compileParts, ' ')
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
