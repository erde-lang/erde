local lib = require('erde.lib')

return {
  compile = require('erde.compile'),
  rewrite = lib.rewrite,
  traceback = lib.traceback,
  pcall = lib.pcall,
  xpcall = lib.xpcall,
  run = lib.run,
  load = lib.load,
  unload = lib.unload,
}
