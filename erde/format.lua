local rules = require('erde.rules')

-- =============================================================================
-- FormatCtx
-- =============================================================================

local FormatCtx = {}

-- Allow calling all rule formatters directly from formatter
for ruleName, rule in pairs(rules) do
  FormatCtx[ruleName] = rule.format
end

-- -----------------------------------------------------------------------------
-- Methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- Format
-- =============================================================================

local format, formatMT = {}, {}
setmetatable(format, formatMT)

formatMT.__call = function(self, text)
  return format.Block(text)
end

for ruleName, rule in pairs(rules) do
  format[ruleName] = function(text, opts)
    local ctx = {}

    -- Keep track of the indent level
    ctx.indentLevel = 0

    return rules[ruleName].format(ctx, opts)
  end
end

return format
