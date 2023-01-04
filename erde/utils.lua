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

-- Remove leading / trailing whitespace from a string.
-- Taken from: https://www.lua.org/pil/20.3.html
local function trim(s)
  return (s:gsub('^%s*(.*)%s*$', '%1'))
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
  return (table.concat({ ... }, C.PATH_SEPARATOR):gsub(C.PATH_SEPARATOR .. '+', C.PATH_SEPARATOR))
end

-- -----------------------------------------------------------------------------
-- Errors
-- -----------------------------------------------------------------------------

local ERDE_ERROR_MT = {
  __tostring = function(self)
    return self.message
  end
}

local function erdeError(err)
  local newErdeError = { __is_erde_error__ = true }

  if type(err) == 'table' then
    for key, value in pairs(err) do
      newErdeError[key] = value
    end
  else
    newErdeError.message = tostring(err)
  end

  setmetatable(newErdeError, ERDE_ERROR_MT)
  error(newErdeError)
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  split = split,
  trim = trim,
  fileExists = fileExists,
  readFile = readFile,
  joinPaths = joinPaths,
  erdeError = erdeError,
}
