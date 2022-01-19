local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Number
-- -----------------------------------------------------------------------------

local Number = { ruleName = 'Number' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Number.parse(ctx)
  local capture = {}
  local branchOpts = { pad = false, capture = capture }

  if ctx:branchStr('0x', branchOpts) or ctx:branchStr('0X', branchOpts) then
    ctx:stream(C.HEX, capture, true)

    if ctx.bufValue == '.' and not ctx:Binop() then
      if _VERSION:find('5%.1') then
        -- Decimal hex values only supported in Lua 5.2+
        error()
      end

      ctx:consume(1, capture)
      ctx:stream(C.HEX, capture, true)
    end

    if ctx:branchChar('p', branchOpts) or ctx:branchChar('P', branchOpts) then
      if _VERSION:find('5%.1') then
        -- Hex exponents only supported in Lua 5.2+
        error()
      end

      ctx:branchChar('+', branchOpts)
      ctx:branchChar('-', branchOpts)
      ctx:stream(C.DIGIT, capture, true)
    end
  else
    while C.DIGIT[ctx.bufValue] do
      ctx:consume(1, capture)
    end

    if ctx.bufValue == '.' and not ctx:Binop() then
      ctx:consume(1, capture)
      ctx:stream(C.DIGIT, capture, true)
    end

    if #capture > 0 then
      if ctx:branchChar('e', branchOpts) or ctx:branchChar('E', branchOpts) then
        ctx:branchChar('+', branchOpts)
        ctx:branchChar('-', branchOpts)
        ctx:stream(C.DIGIT, capture, true)
      end
    end
  end

  if #capture == 0 then
    error()
  end

  return { value = table.concat(capture) }
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Number.compile(ctx, node)
  return node.value
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Number
