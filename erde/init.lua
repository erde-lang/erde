local lib = require('erde.lib')

return {
  compile = require('erde.compile'),
  rewrite = lib.rewrite,
  traceback = lib.traceback,
  pcall = lib.pcallRewrite,
  xpcall = lib.xpcallRewrite,
  run = lib.runString,
  load = lib.load,
  unload = lib.unload,
}
