local utils = {}

function utils.readFile(path)
  local file = io.open(path, 'r')

  if not file then
    return nil
  end

  local content = file:read('*a')
  file:close()

  return content
end

function utils.writeFile(path, content)
  local file = io.open(path, 'w')
  file:write(content)
  file:close()
end

return utils
