local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

local Function = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Function.parse(ctx)
  local node = {
    rule = 'Function',
    variant = ctx:branchWord('local') and 'local' or 'global',
    isMethod = false,
  }

  if not ctx:branchWord('function') then
    ctx:throwExpected('function')
  end

  node.names = { ctx:Name().value }

  while true do
    if ctx:branchChar('.') then
      node.names[#node.names + 1] = ctx:Name().value
    else
      if ctx:branchChar(':') then
        node.isMethod = true
        node.names[#node.names + 1] = ctx:Name().value
      end

      break
    end
  end

  node.params = ctx:Params()
  node.body = ctx:Surround('{', '}', ctx.Block)

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Function.compile(ctx, node)
  local params = ctx:compile(node.params)

  local methodName
  if node.isMethod then
    methodName = table.remove(node.names)
  end

  return ('%s function %s%s(%s)\n%s\n%s\nend'):format(
    node.variant == 'local' and 'local' or '',
    table.concat(node.names, '.'),
    methodName and ':' .. methodName or '',
    table.concat(ctx:compile(params.names), ','),
    params.prebody,
    ctx:compile(node.body)
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Function
