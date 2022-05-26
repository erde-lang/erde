local C = require('erde.constants')
local parse = require('erde.parse')

-- Foward declare rules
local ArrowFunction, Block, Break, Continue, Declaration, ForLoop, Function
local SUB_PRECOMPILERS

-- =============================================================================
-- State
-- =============================================================================

local nodeIdCounter
local blockDepth

-- Keeps track of the top level Block. This is used to register module
-- nodes when using the 'module' scope.
local moduleNode = nil

-- Keeps track of the closest loop block ancestor. This is used to validate
-- Break / Continue nodes, as well as register nested Continue nodes.
local loopBlock = nil

-- =============================================================================
-- Helpers
-- =============================================================================

-- Forward declare
local precompileNode, precompileChildren

local function backup()
  return {
    nodeIdCounter = nodeIdCounter,
    blockDepth = blockDepth,
    moduleNode = moduleNode,
    loopBlock = loopBlock,
  }
end

local function restore(state)
  nodeIdCounter = state.nodeIdCounter
  blockDepth = state.blockDepth
  moduleNode = state.moduleNode
  loopBlock = state.loopBlock
end

function precompileNode(node)
  if type(SUB_PRECOMPILERS[node.tag]) == 'function' then
    SUB_PRECOMPILERS[node.tag](node)
  else
    precompileChildren(node)
  end
end

function precompileChildren(node)
  for key, value in pairs(node) do
    if type(value) == 'table' then
      precompileNode(value)
    end
  end
end

-- =============================================================================
-- Macros
-- =============================================================================

local function Loop(node)
  node.body.continueNodes = {}
  local state = backup()
  loopBlock = node.body
  Block(node.body)
  restore(state)
end

-- =============================================================================
-- Rules
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

function ArrowFunction(node)
  if not node.hasImplicitReturns then
    -- Reset loopBlock for function blocks. Break / Continue cannot traverse these.
    local state = backup()
    loopBlock = nil
    Block(node.body)
    restore(state)
  end
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

function Block(node)
  blockDepth = blockDepth + 1

  for _, child in ipairs(node) do
    precompileNode(child)
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
  if blockDepth > 0 and node.variant == 'module' then
    error(node.variant .. ' declarations must appear at the top level')
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
  -- Reset loopBlock for function blocks. Break / Continue cannot traverse these.
  local state = backup()
  loopBlock = nil
  Block(node.body)
  restore(state)

  if blockDepth > 0 and node.variant == 'module' then
    error(node.variant .. ' declarations must appear at the top level')
  end

  if blockDepth == 0 and node.variant ~= 'global' and #node.names == 1 then
    node.isHoisted = true
    table.insert(moduleNode.hoistedNames, node.names[1])
  end

  if node.variant == 'module' then
    if #node.names > 1 then
      error('Cannot declare nested field as ' .. node.variant)
    end

    table.insert(moduleNode.exportNames, node.names[1])
  end
end

-- =============================================================================
-- Precompile
-- =============================================================================

SUB_PRECOMPILERS = {
  ArrowFunction = ArrowFunction,
  Block = Block,
  Break = Break,
  Continue = Continue,
  Declaration = Declaration,
  ForLoop = ForLoop,
  Function = Function,
  Module = Module,
  RepeatUntil = Loop,
  WhileLoop = Loop,
}

return function(ast)
  nodeIdCounter = 1
  blockDepth = 0
  moduleNode = nil

  -- Table for Declaration and Function nodes to register `module` scope
  -- variables.
  ast.exportNames = {}

  -- Table for all top-level declared names. These are hoisted for convenience
  -- to have more "module-like" behavior prevalent in other languages.
  ast.hoistedNames = {}

  moduleNode = ast

  for _, child in ipairs(ast) do
    precompileNode(child)
  end

  if #ast.exportNames > 0 then
    for i, statement in ipairs(ast) do
      if statement.tag == 'Return' then
        -- Block cannot use both `return` and `module`
        -- TODO: not good enough! What about conditional return?
        error()
      end
    end
  end
end
