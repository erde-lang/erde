local Environment = require('erde.Environment')
local constants = require('erde.constants')
local rules = require('erde.rules')

-- -----------------------------------------------------------------------------
-- ProcessorContext
-- -----------------------------------------------------------------------------

local ProcessorContext = {}
local ProcessorContextMT = { __index = ProcessorContext }

for ruleName, processor in pairs(rules.process) do
  ProcessorContext[ruleName] = processor
end

function ProcessorContext:load(root)
  self.root = root
  self.rulePath = {}
end

function ProcessorContext:traverse(node)
  for i, child in ipairs(node) do
    if type(child) == 'table' then
      if child.ruleName == nil then
        self:traverse(child)
      else
        self.rulePath[#self.rulePath + 1] = node
        self:traverse(child)
        self.rulePath[#self.rulePath] = nil

        if type(ProcessorContext[node.ruleName]) == 'function' then
          ProcessorContext[node.ruleName](self, node)
        end
      end
    end
  end
end

function ProcessorContext:process(root)
  self:load(root)
  self:traverse(root)
end

-- -----------------------------------------------------------------------------
-- Error Handling
-- -----------------------------------------------------------------------------

function ProcessorContext:throwError(msg)
  error(('Error (Line %d, Col %d): %s'):format(self.line, self.column, msg))
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return function()
  return setmetatable({}, ProcessorContextMT)
end
