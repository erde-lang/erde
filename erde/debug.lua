local function rewrite(err, sourceMap, sourceName)
  errSource, errLine, errMsg = err:match('^(.*):(%d+): (.*)$')
  errLine = tonumber(errLine)

  if sourceMap == nil then
    -- TODO: use sourceMapCache
  end

  return ('%s:%d: %s'):format(
    sourceName or errSource,
    sourceMap ~= nil and sourceMap[errLine] or errLine,
    errMsg
  )
end

local function traceback()
  -- TODO
end

return { rewrite = rewrite, traceback = traceback }
