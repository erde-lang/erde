local function read_file(path)
  local file = io.open(path, 'r')

  if not file then
    return nil
  end

  local content = file:read('*a')
  file:close()

  return content
end

local function write_file(path, content)
  local file = io.open(path, 'w')
  file:write(content)
  file:close()
end
