-- -----------------------------------------------------------------------------
-- Rules
-- -----------------------------------------------------------------------------

local rules = {
  parse = {},
  compile = {},
}

function rules:register(rule)
  local ruleName = rule.ruleName

  self.parse[ruleName] = function(ctx, ...)
    ctx:Space()
    local node = rule.parse(ctx, ...)
    ctx:Space()

    if node.ruleName == nil then
      node.ruleName = ruleName
    end

    return node
  end

  self.compile[ruleName] = function(ctx, node, ...)
    local compiled = rule.compile(ctx, node, ...)
    return node.parens and '(' .. compiled .. ')' or compiled
  end
end

-- -----------------------------------------------------------------------------
-- Rule Modules
-- -----------------------------------------------------------------------------

rules:register(require('erde.rules.ArrowFunction'))
rules:register(require('erde.rules.Assignment'))
rules:register(require('erde.rules.Block'))
rules:register(require('erde.rules.Break'))
rules:register(require('erde.rules.Comment'))
rules:register(require('erde.rules.Continue'))
rules:register(require('erde.rules.Declaration'))
rules:register(require('erde.rules.Destructure'))
rules:register(require('erde.rules.DoBlock'))
rules:register(require('erde.rules.Expr'))
rules:register(require('erde.rules.ForLoop'))
rules:register(require('erde.rules.Function'))
rules:register(require('erde.rules.FunctionCall'))
rules:register(require('erde.rules.Id'))
rules:register(require('erde.rules.IfElse'))
rules:register(require('erde.rules.Name'))
rules:register(require('erde.rules.Number'))
rules:register(require('erde.rules.OptChain'))
rules:register(require('erde.rules.Params'))
rules:register(require('erde.rules.Pipe'))
rules:register(require('erde.rules.RepeatUntil'))
rules:register(require('erde.rules.Return'))
rules:register(require('erde.rules.Spread'))
rules:register(require('erde.rules.String'))
rules:register(require('erde.rules.Table'))
rules:register(require('erde.rules.Terminal'))
rules:register(require('erde.rules.TryCatch'))
rules:register(require('erde.rules.WhileLoop'))

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return rules
