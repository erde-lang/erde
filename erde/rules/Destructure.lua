local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

local Destructure = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Destructure.parse(ctx)
  local node = {}
  local keyCounter = 1

  if ctx:branchChar('?') then
    node.optional = true
  end

  if not ctx:branchChar('{') then
    ctx:throwExpected('{')
  end

  while not ctx:branchChar('}') do
    local field = {}

    if ctx:branchChar(':') then
      field.variant = 'mapDestruct'
      field.name = ctx:Name().value
      field.destructure = ctx:Try(ctx.Destructure)
    else
      field.variant = 'arrayDestruct'
      field.key = keyCounter
      keyCounter = keyCounter + 1

      local name = ctx:Try(ctx.Name)
      if name then
        field.name = name.value
      else
        field.destructure = ctx:Destructure()
      end
    end

    if ctx:branchChar('=') then
      field.default = ctx:Expr()
    end

    node[#node + 1] = field

    if not ctx:branchChar(',') and ctx.bufValue ~= '}' then
      ctx:throwError('Missing trailing comma')
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Destructure.compile(ctx, node)
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Destructure
