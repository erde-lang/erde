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
-- TODO
-- -----------------------------------------------------------------------------

function compiler.DoBlock(node)
  local compiled = {}
  return table.concat(compiled, '\n')
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
-- TODO
-- -----------------------------------------------------------------------------

function compiler.ForLoop(node)
  local compiled = {}
  return table.concat(compiled, '\n')
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
-- TODO
-- -----------------------------------------------------------------------------

function compiler.IfElse(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Name
-- TODO
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
-- TODO
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
-- TODO
-- -----------------------------------------------------------------------------

function compiler.Table(node)
  local compiled = {}
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Rule: Terminal
-- TODO
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
