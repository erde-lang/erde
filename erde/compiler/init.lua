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

-- -----------------------------------------------------------------------------
-- Rule: ArrowFunction
-- TODO
-- -----------------------------------------------------------------------------

function compiler.ArrowFunction(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Assignment
-- TODO
-- -----------------------------------------------------------------------------

function compiler.Assignment(node)
  local compiled = {}
  return table.concat(compiled, '\n')
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
  return node.variant == 'numeric'
      and ('for %s=%s,%s,%s do\n%s\nend'):format(
        node.name,
        node.var,
        node.limit,
        node.step or '1',
        compile(node.body)
      )
    or ('for %s in %s do\n%s\nend'):format(
      table.concat(node.nameList, ','),
      table.concat(node.exprList, ','),
      compile(node.body)
    )
end

-- -----------------------------------------------------------------------------
-- Rule: Function
-- TODO
-- -----------------------------------------------------------------------------

function compiler.Function(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: FunctionCall
-- TODO
-- -----------------------------------------------------------------------------

function compiler.FunctionCall(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Id
-- TODO
-- -----------------------------------------------------------------------------

function compiler.Id(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: IfElse
-- -----------------------------------------------------------------------------

function compiler.IfElse(node)
  local compiled = {
    'if ' .. node.cond .. ' then',
    compile(node.body),
  }

  for _, elseifNode in ipairs(node.elseifNodes) do
    compiled[#compiled + 1] = 'elseif ' .. elseifNode.cond .. ' then'
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
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: RepeatUntil
-- TODO
-- -----------------------------------------------------------------------------

function compiler.RepeatUntil(node)
  local compiled = {}
  return table.concat(compiled, '\n')
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
-- TODO
-- -----------------------------------------------------------------------------

function compiler.Table(node)
  local compiled = {}
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
-- TODO
-- -----------------------------------------------------------------------------

function compiler.Var(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: WhileLoop
-- TODO
-- -----------------------------------------------------------------------------

function compiler.WhileLoop(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return compiler
