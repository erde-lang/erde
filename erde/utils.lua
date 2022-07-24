local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Strings
-- -----------------------------------------------------------------------------

local function split(s, separator)
  separator = separator or '%s'
  local parts = {}

  for part in s:gmatch('([^' .. separator .. ']+)') do
    table.insert(parts, part)
  end

  return parts
end

-- -----------------------------------------------------------------------------
-- Files
-- -----------------------------------------------------------------------------

local function fileExists(filePath)
  local file = io.open(filePath, 'r')

  if file == nil then
    return false
  end

  file:close()
  return true
end

local function readFile(filePath)
  local file = io.open(filePath)

  if file == nil then
    error('file does not exist: ' .. filePath)
  end

  local contents = file:read('*a')
  file:close()
  return contents
end

-- -----------------------------------------------------------------------------
-- Paths
-- -----------------------------------------------------------------------------

local function joinPaths(...)
  return table.concat({ ... }, C.PATH_SEPARATOR)
    :gsub(C.PATH_SEPARATOR .. '+', C.PATH_SEPARATOR)
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  split = split,
  fileExists = fileExists,
  readFile = readFile,
  joinPaths = joinPaths,
}
