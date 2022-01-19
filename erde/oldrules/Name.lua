local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Name
-- -----------------------------------------------------------------------------

local Name = { ruleName = 'Name' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Name.parse(ctx)
  if not C.ALPHA[ctx.bufValue] and ctx.bufValue ~= '_' then
    -- name must start with alpha or underscore
    error()
  end

  local capture = {}
  ctx:consume(1, capture)

  while C.ALNUM[ctx.bufValue] or ctx.bufValue == '_' do
    ctx:consume(1, capture)
  end

  local value = table.concat(capture)
  for _, keyword in pairs(C.KEYWORDS) do
    if value == keyword then
      -- name cannot be keyword
      error()
    end
  end

  return { value = table.concat(capture) }
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Name.compile(ctx, node)
  return node.value
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Name
