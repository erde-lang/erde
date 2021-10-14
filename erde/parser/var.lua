local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parser.var()
  local node = {}

  if Whitespace[buffer[bufIndex + #'local']] and branchWord('local') then
    node.tag = TAG_LOCAL_VAR
  elseif Whitespace[buffer[bufIndex + #'global']] and branchWord('global') then
    node.tag = TAG_GLOBAL_VAR
  else
    return nil
  end

  node.name = pad(parser.name)

  if branchChar('=') then
    node.initValue = pad(parser.expr)
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.var(input)
  loadBuffer(input)
  return parser.var()
end
