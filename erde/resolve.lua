local C = require('erde.constants')
local parse = require('erde.parse')

-- Foward declare rules
local ArrowFunction, Assignment, Block, Break, Continue, Declaration, Destructure, DoBlock, Expr, ForLoop, Function, FunctionCall, Goto, Id, IfElse, OptChain, Params, RepeatUntil, Return, Self, Spread, String, Table, TryCatch, WhileLoop
local SUB_RESOLVERS

-- =============================================================================
-- State
-- =============================================================================

local nodeIdCounter
local blockDepth

-- Keeps track of the top level Block. This is used to register module
-- nodes when using the 'module' scope.
local moduleNode = nil

-- Keeps track of the Block body of the closest loop ancestor (ForLoop,
-- RepeatUntil, WhileLoop). This is used to validate and link Break and
-- Continue statements.
local loopBlock = nil

-- =============================================================================
-- Helpers
-- =============================================================================

-- Forward declare
local resolveNode, resolveTree

local function reset(node)
  nodeIdCounter = 1
  blockDepth = 0
  moduleNode = nil
end

function resolveNode(node)
  if type(SUB_RESOLVERS[node.ruleName]) == 'function' then
    SUB_RESOLVERS[node.ruleName](node)
  else
    resolveTree(node)
  end
end

function resolveTree(tree)
  for key, value in pairs(tree) do
    if type(value) == 'table' then
      if value.ruleName ~= nil then
        resolveNode(value)
      else
        resolveTree(value)
      end
    end
  end
end

-- =============================================================================
-- Pseudo Rules
-- =============================================================================

-- =============================================================================
-- Rules
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

function ArrowFunction(node)
  -- Reset loopBlock for function blocks. Break / Continue cannot
  -- traverse these.
  local loopBlockBackup = loopBlock
  loopBlock = nil
  resolveTree(node)
  loopBlock = loopBlockBackup
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

function Block(node)
  blockDepth = blockDepth + 1

  for _, statement in ipairs(node) do
  end

  blockDepth = blockDepth - 1
end

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

function Break(node)
  assert(loopBlock ~= nil, 'Cannot use `break` outside of loop')
end

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

function Continue(node)
  assert(loopBlock ~= nil, 'Cannot use `continue` outside of loop')
  table.insert(loopBlock.continueNodes, node)
end

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

function Declaration(node)
  if
    blockDepth > 0 and (node.variant == 'module' or node.variant == 'main')
  then
    error(node.variant .. ' declarations must appear at the top level')
  end

  if node.variant == 'main' then
    if
      #node.varList > 1
      or type(node.varList[1]) ~= 'string'
      or moduleNode.mainName ~= nil
    then
      error('Cannot have multiple `main` declarations')
    end

    moduleNode.mainName = node.varList[1]
  end

  if blockDepth == 0 and node.variant ~= 'global' then
    node.isHoisted = true

    local nameList = {}
    for _, var in ipairs(node.varList) do
      if type(var) == 'string' then
        table.insert(nameList, var)
      else
        for _, destruct in ipairs(var) do
          table.insert(nameList, destruct.alias or destruct.name)
        end
      end
    end

    for _, name in ipairs(nameList) do
      table.insert(moduleNode.hoistedNames, name)
    end

    if node.variant == 'module' then
      for _, name in ipairs(nameList) do
        table.insert(moduleNode.exportNames, name)
      end
    end
  end
end

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

function ForLoop(node)
  loopBlock = node.body
  node.body.continueNodes = {}
  resolveTree(node)
end

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

function Function(node)
  -- Reset loopBlock for function blocks. Break / Continue cannot
  -- traverse these.
  local loopBlockBackup = loopBlock
  loopBlock = nil
  resolveTree(node)
  loopBlock = loopBlockBackup
end

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

function Module(node)
  moduleNode = node

  resolveTree(node)

  if #node.exportNames > 0 then
    for i, statement in ipairs(node) do
      if statement.ruleName == 'Return' then
        -- Block cannot use both `return` and `module`
        -- TODO: not good enough! What about conditional return?
        error()
      end
    end
  end
end

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

function RepeatUntil(node)
  loopBlock = node.body
  node.body.continueNodes = {}
  resolveTree(node)
end

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

function WhileLoop(node)
  loopBlock = node.body
  node.body.continueNodes = {}
  resolveTree(node)
end

-- =============================================================================
-- Resolve
-- =============================================================================

local resolve, resolveMT = {}, {}
setmetatable(resolve, resolveMT)

resolveMT.__call = function(self, ast)
  reset()
  return resolveNode(ast)
end

SUB_RESOLVERS = {
  -- Rules
  ArrowFunction = ArrowFunction,
  Assignment = Assignment,
  Block = Block,
  Break = Break,
  Continue = Continue,
  Declaration = Declaration,
  Destructure = Destructure,
  DoBlock = DoBlock,
  Expr = Expr,
  ForLoop = ForLoop,
  Function = Function,
  Goto = Goto,
  IfElse = IfElse,
  Module = Module,
  OptChain = OptChain,
  Params = Params,
  RepeatUntil = RepeatUntil,
  Return = Return,
  Self = Self,
  Spread = Spread,
  String = String,
  Table = Table,
  TryCatch = TryCatch,
  WhileLoop = WhileLoop,

  -- Pseudo-Rules
  -- Var = Var,
  -- Name = Name,
  -- Number = Number,
  -- Terminal = Terminal,
  FunctionCall = OptChain,
  Id = OptChain,
}

for name, subResolver in pairs(SUB_RESOLVERS) do
  resolve[name] = function(ast)
    reset()
    return subResolver(ast)
  end
end

return resolve
