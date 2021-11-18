local utils = require('erde.utils')

-- -----------------------------------------------------------------------------
-- Pipe
-- -----------------------------------------------------------------------------

local Pipe = { ruleName = 'Pipe' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Pipe.parse(ctx, initValues)
  local node = { initValues = initValues }

  while ctx:branchStr('>>') do
    node[#node + 1] = ctx:Expr()
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
    pipeArgs = pipeResult
    pipeResult = ctx.newTmpName()

    local receiver
    if pipe.ruleName == 'OptChain' then
      local lastChain = pipe[#pipe]
      if lastChain and lastChain.variant == 'functionCall' then
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

        local pipeCopy = utils.shallowCopy(pipe) -- Do not mutate AST
        table.remove(pipeCopy)
        receiver = ctx:compile(pipeCopy)
      end
    end

    compiled[#compiled + 1] = ctx.format(
      'local %1 = { %2(%3(%4)) }',
      pipeResult,
      receiver or ctx:compile(pipe),
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
