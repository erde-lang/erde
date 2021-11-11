local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Pipe
-- -----------------------------------------------------------------------------

local Pipe = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Pipe.parse(ctx)
  local node = {
    rule = 'Pipe',
    initValues = ctx.bufValue ~= '(' and { ctx:Expr() } or ctx:Parens({
      demand = true,
      allowRecursion = true,
      rule = function()
        return ctx:List({
          allowTrailingComma = true,
          rule = ctx.Expr,
        })
      end,
    }),
  }

  while true do
    local backup = ctx:backup()
    local pipe = { optional = ctx:branchChar('?') }

    if not ctx:branchStr('>>') then
      ctx:restore(backup) -- revert consumption from ctx:branchChar('?')
      break
    end

    pipe.receiver = ctx:Expr()
    node[#node + 1] = pipe
  end

  if #node == 0 then
    ctx:throwExpected('>>')
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

local unpackCompiled = _VERSION:find('5.1') and 'unpack' or 'table.unpack'

function Pipe.compile(ctx, node)
  local compiled = {}

  local initValues = {}
  for i, initValue in ipairs(node.initValues) do
    initValues[#initValues + 1] = ctx:compile(initValue)
  end

  local pipeArgs = table.concat(initValues, ',')
  local pipeResult = ctx.newTmpName()
  compiled[#compiled + 1] = ctx.format(
    'local %1 = { %2 }',
    pipeResult,
    pipeArgs
  )

  for i, pipe in ipairs(node) do
    if pipe.optional then
      compiled[#compiled + 1] = ctx.format(
        'if #%1 == 0 then return end',
        pipeResult
      )
    end

    pipeArgs = pipeResult
    pipeResult = ctx.newTmpName()

    -- TODO: check for optchain
    -- insert into pipeArgs var
    -- compile optchain
    local pipe = ctx:compile(pipe.receiver)

    compiled[#compiled + 1] = ctx.format(
      'local %1 = { %2(%3(%4)) }',
      pipeResult,
      pipe,
      unpackCompiled,
      pipeArgs
    )
  end

  return table.concat({
    '(function()',
    table.concat(compiled, '\n'),
    ctx.format('return %1(%2)', unpackCompiled, pipeResult),
    'end)()',
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Pipe
