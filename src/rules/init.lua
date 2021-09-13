local lpeg = require('lpeg')
local supertable = require('supertable')

return supertable()
  :merge(require('rules.Core'))
  :merge(require('rules.Primitives'))
  :merge(require('rules.Tables'))
  :merge(require('rules.Operators'))
  :merge(require('rules.Expr'))
  :merge(require('rules.Block'))
  :reduce(function(rules, rule, rulename)
    rules.parser:merge({ [rulename] = rule.parser })
    rules.compiler:merge({ [rulename] = rule.parser })
    return rules
  end, {
    parser = supertable({ lpeg.V('Block') }),
    compiler = supertable(),
  })
