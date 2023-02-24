local C = require('erde.constants')
local lfs = require('lfs')

local function join_paths(...)
  -- Include surrounding parens to only capture first return
  return (table.concat({ ... }, C.PATH_SEPARATOR):gsub(C.PATH_SEPARATOR .. '+', C.PATH_SEPARATOR))
end

local function terminate(message, status)
  print(message)
  os.exit(status or 1)
end

local function traverse(paths, pattern, callback)
  for i, path in ipairs(paths) do
    local attributes = lfs.attributes(path)

    if attributes ~= nil then
      if attributes.mode == 'file' then
        if pattern == nil or path:match(pattern) then
          callback(path, attributes)
        end
      elseif attributes.mode == 'directory' then
        local subpaths = {}

        for filename in lfs.dir(path) do
          if filename ~= '.' and filename ~= '..' then
            table.insert(subpaths, join_paths(path, filename))
          end
        end

        traverse(subpaths, pattern, callback)
      end
    end
  end
end

-- Check whether a file has been generated from `erde` by checking if the file
-- ends with `C.COMPILED_FOOTER_COMMENT`.
local function is_compiled_file(path)
  local file = io.open(path, 'r')
  if file == nil then return false end

  -- Some editors save an invisible trailing newline, so read an extra char just
  -- in case.
  local read_len = #C.COMPILED_FOOTER_COMMENT + 1

  file:seek('end', -read_len)
  local footer = file:read(read_len)
  file:close()

  return footer and footer:find(C.COMPILED_FOOTER_COMMENT)
end


return {
  is_compiled_file = is_compiled_file,
  join_paths = join_paths,
  terminate = terminate,
  traverse = traverse,
}
