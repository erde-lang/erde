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

local function file_exists(path)
  local file = io.open(path, 'r')

  if file == nil then
    return false
  end

  file:close()
  return true
end

local function read_file(path)
  local file = io.open(path)

  if file == nil then
    error('file does not exist: ' .. path)
  end

  local contents = file:read('*a')
  file:close()
  return contents
end

-- -----------------------------------------------------------------------------
-- Paths
-- -----------------------------------------------------------------------------

local function join_paths(...)
  return (table.concat({ ... }, C.PATH_SEPARATOR):gsub(C.PATH_SEPARATOR .. '+', C.PATH_SEPARATOR))
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  split = split,
  trim = trim,
  file_exists = file_exists,
  read_file = read_file,
  join_paths = join_paths,
}
