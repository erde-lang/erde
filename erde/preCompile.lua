local C = require('erde.constants')
local parse = require('erde.parse')

-- Foward declare
local preCompilers = {}
local preCompileChildren
local Block

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local nodeIdCounter
local blockDepth

-- Keeps track of the top level Block. This is used to register module
-- nodes when using the 'module' scope.
local moduleNode

-- Keeps track of the closest loop block ancestor. This is used to validate
-- Break / Continue nodes, as well as register nested Continue nodes.
local loopBlock

-- Keeps track of whether the module has a `return` statement. Used to warn the
-- developer if they try to combine `return` with `module` scopes.
local isInModuleReturnBlock, hasModuleReturn

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

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

function preCompileNode(node)
  if type(preCompilers[node.tag]) == 'function' then
    preCompilers[node.tag](node)
  else
    preCompileChildren(node)
  end
end

function preCompileChildren(node)
  for key, value in pairs(node) do
    if type(value) == 'table' then
      preCompileNode(value)
    end
  end
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

local function Loop(node)
  node.body.continueNodes = {}
  local state = backup()
  loopBlock = node.body
  preCompilers.Block(node.body)
  restore(state)
end

local function FunctionBlock(node)
  local state = backup()

  -- Reset isInModuleReturnBlock
  isInModuleReturnBlock = false

    -- Reset loopBlock for function blocks. Break / Continue cannot traverse these.
  loopBlock = nil

  preCompilers.Block(node.body)
  restore(state)
end

-- -----------------------------------------------------------------------------
-- PreCompilers
-- -----------------------------------------------------------------------------

preCompilers = {
  GenericFor = Loop,
  RepeatUntil = Loop,
  WhileLoop = Loop,
}

function preCompilers.ArrowFunction(node)
  if not node.hasImplicitReturns then
    FunctionBlock(node)
  end
end

function preCompilers.Block(node)
  blockDepth = blockDepth + 1

  for _, child in ipairs(node) do
    preCompileNode(child)
  end

  blockDepth = blockDepth - 1
end

function preCompilers.Break(node)
  assert(loopBlock ~= nil, 'Cannot use `break` outside of loop')
end

function preCompilers.Continue(node)
  assert(loopBlock ~= nil, 'Cannot use `continue` outside of loop')
  table.insert(loopBlock.continueNodes, node)
end

function preCompilers.Declaration(node)
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

function preCompilers.Function(node)
  FunctionBlock(node)

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

function preCompilers.NumericFor(node)
  if #node.parts < 2 then
    error('Invalid for loop parameters (missing parameters)')
  elseif #node.parts > 3 then
    error('Invalid for loop parameters (too many parameters)')
  end

  Loop(node)
end

function preCompilers.Return(node)
  if isInModuleReturnBlock then
    hasModuleReturn = true
  end
end

-- -----------------------------------------------------------------------------
-- PreCompile
-- -----------------------------------------------------------------------------

return function(ast)
  nodeIdCounter = 1
  blockDepth = 0
  isInModuleReturnBlock = true
  hasModuleReturn = false
  moduleNode = ast

  -- Table for Declaration and Function nodes to register `module` scope
  -- variables.
  moduleNode.exportNames = {}

  -- Table for all top-level declared names. These are hoisted for convenience
  -- to have more "module-like" behavior prevalent in other languages.
  moduleNode.hoistedNames = {}

  for _, child in ipairs(moduleNode) do
    preCompileNode(child)
  end

  if hasModuleReturn and #moduleNode.exportNames > 0 then
    error('Cannot use both `return` and `module` together.')
  end
end
