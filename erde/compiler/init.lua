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
-- -----------------------------------------------------------------------------

function compiler.ArrowFunction(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Assignment
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
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Destructure
-- -----------------------------------------------------------------------------

function compiler.Destructure(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: DoBlock
-- -----------------------------------------------------------------------------

function compiler.DoBlock(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Expr
-- -----------------------------------------------------------------------------

function compiler.Expr(minPrec)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: ForLoop
-- -----------------------------------------------------------------------------

function compiler.ForLoop(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Function
-- -----------------------------------------------------------------------------

function compiler.Function(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: FunctionCall
-- -----------------------------------------------------------------------------

function compiler.FunctionCall(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Id
-- -----------------------------------------------------------------------------

function compiler.Id(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: IfElse
-- -----------------------------------------------------------------------------

function compiler.IfElse(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Name
-- -----------------------------------------------------------------------------

function compiler.Name(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Number
-- -----------------------------------------------------------------------------

function compiler.Number(node)
  return node.value
end

-- -----------------------------------------------------------------------------
-- Rule: OptChain
-- -----------------------------------------------------------------------------

function compiler.OptChain(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Params
-- -----------------------------------------------------------------------------

function compiler.Params(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: RepeatUntil
-- -----------------------------------------------------------------------------

function compiler.RepeatUntil(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Return
-- -----------------------------------------------------------------------------

function compiler.Return(node)
  local compiled = {}
  return table.concat(compiled, '\n')
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
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Terminal
-- -----------------------------------------------------------------------------

function compiler.Terminal(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Var
-- -----------------------------------------------------------------------------

function compiler.Var(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: WhileLoop
-- -----------------------------------------------------------------------------

function compiler.WhileLoop(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return compiler
