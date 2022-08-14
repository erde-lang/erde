local lib = require('erde.lib')

return {
  compile = require('erde.compile'),
  rewrite = lib.rewrite,
  traceback = lib.traceback,
  run = lib.run,
  load = lib.load,
  unload = lib.unload,
}
