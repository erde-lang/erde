local rules = {}

local function register(rule)
  rules[rule.ruleName] = {
    parse = function(ctx, ...)
      local node = rule.parse(ctx, ...)

      if node.ruleName == nil then
        node.ruleName = rule.ruleName
      end

      return node
    end,

    compile = function(ctx, node, ...)
      local compiled = rule.compile(ctx, node, ...)

      if node.parens then
        compiled = '(' .. compiled .. ')'
      end

      return compiled
    end,
  }
end

register(require('erde.rules.ArrowFunction'))
register(require('erde.rules.Assignment'))
register(require('erde.rules.Block'))
register(require('erde.rules.Break'))
register(require('erde.rules.Continue'))
register(require('erde.rules.Declaration'))
register(require('erde.rules.Destructure'))
register(require('erde.rules.DoBlock'))
register(require('erde.rules.Expr'))
register(require('erde.rules.ForLoop'))
register(require('erde.rules.Function'))
register(require('erde.rules.FunctionCall'))
register(require('erde.rules.Goto'))
register(require('erde.rules.Id'))
register(require('erde.rules.IfElse'))
register(require('erde.rules.Name'))
register(require('erde.rules.Number'))
register(require('erde.rules.OptChain'))
register(require('erde.rules.Params'))
register(require('erde.rules.Pipe'))
register(require('erde.rules.RepeatUntil'))
register(require('erde.rules.Return'))
register(require('erde.rules.Spread'))
register(require('erde.rules.String'))
register(require('erde.rules.Table'))
register(require('erde.rules.Terminal'))
register(require('erde.rules.TryCatch'))
register(require('erde.rules.WhileLoop'))

return rules
