-- NOTE: When writing resolvers, nodes should be treated as IMMUTABLE before
-- calling `resolveChildren()`, since mutating the node beforehand may cause
-- unintentional iterations over newly created values.

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

-- Flag that holds whether the current resolver has an encompassing loop node.
-- This is used to validate Break and Continue nodes.
local isLoopBlock = nil

-- Table for Continue nodes to register themselves in. This is used by loop
-- nodes to link any nested Continue nodes.
local loopContinueNodes = nil

-- =============================================================================
-- Helpers
-- =============================================================================

-- Forward declare
local resolveNode, resolveChildren

local function reset(node)
  nodeIdCounter = 1
  blockDepth = 0
  moduleNode = nil
end

local function backup()
  return {
    nodeIdCounter = nodeIdCounter,
    blockDepth = blockDepth,
    moduleNode = moduleNode,
    isLoopBlock = isLoopBlock,
    loopContinueNodes = loopContinueNodes,
  }
end

local function restore(state)
  nodeIdCounter = state.nodeIdCounter
  blockDepth = state.blockDepth
  moduleNode = state.moduleNode
  isLoopBlock = state.isLoopBlock
  loopContinueNodes = state.loopContinueNodes
end

function resolveNode(node)
  if type(SUB_RESOLVERS[node.ruleName]) == 'function' then
    SUB_RESOLVERS[node.ruleName](node)
  else
    resolveChildren(node)
  end
end

function resolveChildren(node)
  for key, value in pairs(node) do
    if type(value) == 'table' then
      resolveNode(value)
    end
  end
end

-- =============================================================================
-- Pseudo Rules
-- =============================================================================

local function Loop(node)
  local state = backup()
  isLoopBlock = true
  loopContinueNodes = {}
  resolveChildren(node)
  node.body.continueNodes = loopContinueNodes
  restore(state)
end

-- =============================================================================
-- Rules
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

function ArrowFunction(node)
  local state = backup()
  -- Reset loopBlock for function blocks. Break / Continue cannot traverse these.
  isLoopBlock = false
  resolveChildren(node)
  restore(state)
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

function Block(node)
  blockDepth = blockDepth + 1
  resolveChildren(node)
  blockDepth = blockDepth - 1
end

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

function Break(node)
  assert(isLoopBlock, 'Cannot use `break` outside of loop')
end

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

function Continue(node)
  assert(isLoopBlock, 'Cannot use `continue` outside of loop')
  table.insert(loopContinueNodes, node)
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

  resolveChildren(node)
end

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

function ForLoop(node)
  if node.variant == 'numeric' then
    if #node.parts < 2 then
      error('Invalid for loop parameters (missing parameters)')
    elseif #node.parts > 3 then
      error('Invalid for loop parameters (too many parameters)')
    end
  end

  Loop(node)
end

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

function Function(node)
  local state = backup()
  -- Reset loopBlock for function blocks. Break / Continue cannot traverse these.
  isLoopBlock = false
  resolveChildren(node)
  restore(state)

  if
    blockDepth > 0 and (node.variant == 'module' or node.variant == 'main')
  then
    error(node.variant .. ' declarations must appear at the top level')
  end

  if blockDepth == 0 and node.variant ~= 'global' and #node.names == 1 then
    node.isHoisted = true
    table.insert(moduleNode.hoistedNames, node.names[1])
  end

  if node.variant == 'module' or node.variant == 'main' then
    if #node.names > 1 then
      error('Cannot declare nested field as ' .. node.variant)
    end

    if node.variant == 'main' then
      if moduleNode.mainName ~= nil then
        error('Cannot have multiple main declarations')
      end

      moduleNode.mainName = node.names[1]
    else
      table.insert(moduleNode.exportNames, node.names[1])
    end
  end
end

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

function Module(node)
  -- Table for Declaration and Function nodes to register `module` scope
  -- variables.
  node.exportNames = {}

  -- Return name for this block. Only valid at the top level.
  node.mainName = nil

  -- Table for all top-level declared names. These are hoisted for convenience
  -- to have more "module-like" behavior prevalent in other languages.
  node.hoistedNames = {}

  moduleNode = node
  resolveChildren(node)

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
  RepeatUntil = Loop,
  Return = Return,
  Self = Self,
  Spread = Spread,
  String = String,
  Table = Table,
  TryCatch = TryCatch,
  WhileLoop = Loop,

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
