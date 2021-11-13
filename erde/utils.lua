-- -----------------------------------------------------------------------------
-- Utils
-- -----------------------------------------------------------------------------

local utils = {}

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

function utils.load(code)
  local runner
  if _VERSION:find('5.1') then
    runner = loadstring(code)
  else
    runner = load(code)
  end

  if runner == nil then
    error('Invalid Lua code: ' .. code)
  end

  return runner
end

function utils.eval(expr)
  return utils.load('return ' .. expr)()
end

function utils.run(code)
  return utils.load(code)()
end

function utils.shallowCopy(t)
  if type(t) ~= 'table' then
    return t
  end

  local copy = {}

  for key, value in pairs(t) do
    copy[key] = value
  end

  return copy
end

function utils.deepCompare(a, b)
  if type(a) ~= 'table' or type(b) ~= 'table' then
    return a == b
  end

  for key in pairs(a) do
    if not utils.deepCompare(a[key], b[key]) then
      return false
    end
  end

  return true
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return utils
