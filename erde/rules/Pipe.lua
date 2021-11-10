local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Pipe
-- -----------------------------------------------------------------------------

local Pipe = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Pipe.parse(ctx)
  local node = { rule = 'Pipe', base = ctx:OptChain() }

  while true do
    local backup = ctx:backup()
    local pipe = { optional = ctx:branchChar('?') }

    if not ctx:branchStr('>>') then
      ctx:restore(backup) -- revert consumption from ctx:branchChar('?')
      break
    end

    pipe.optChain = ctx:OptChain()
    node[#node + 1] = pipe
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Pipe.compile(ctx, node)
  return node.value
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Pipe
