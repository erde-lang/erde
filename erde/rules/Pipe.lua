local utils = require('erde.utils')

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
    initValues = ctx:Surround('[', ']', function()
      return ctx:List({
        allowEmpty = true,
        allowTrailingComma = true,
        rule = ctx.Expr,
      })
    end),
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

    local receiver
    if pipe.receiver.rule == 'OptChain' then
      local lastChain = pipe.receiver[#pipe.receiver]
      if lastChain and lastChain.variant == 'params' then
        local pipeArgsLen = ctx.newTmpName()
        compiled[#compiled + 1] = ctx.format(
          'local %1 = #%2',
          pipeArgsLen,
          pipeArgs
        )

        for i, expr in ipairs(lastChain.value) do
          compiled[#compiled + 1] = ctx.format(
            '%1[%2 + %3] = %4',
            pipeArgs,
            pipeArgsLen,
            i,
            ctx:compile(expr)
          )
        end

        local receiverCopy = utils.shallowCopy(pipe.receiver) -- Do not mutate AST
        table.remove(receiverCopy)
        receiver = ctx:compile(receiverCopy)
      end
    else
      receiver = ctx:compile(pipe.receiver)
    end

    compiled[#compiled + 1] = ctx.format(
      'local %1 = { %2(%3(%4)) }',
      pipeResult,
      receiver,
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
