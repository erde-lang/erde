local rules = require('erde.rules')

-- =============================================================================
-- Formatter
-- =============================================================================

local Formatter = {}
local FormatterMT = { __index = Parser }

-- Allow calling all rule formatters directly from formatter
for ruleName, rule in pairs(rules) do
  Formatter[ruleName] = rule.format
end

-- -----------------------------------------------------------------------------
-- Methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- Format
-- =============================================================================

local format, formatMT = {}, {}

formatMT.__call = function(self, text)
  return format.Block(text)
end

for ruleName, rule in pairs(rules) do
  format[ruleName] = function(text, opts)
    local ctx = {}
    return rules[ruleName].format(ctx, opts)
  end
end

setmetatable(format, formatMT)
return format
