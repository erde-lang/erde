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
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Function
