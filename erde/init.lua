local lib = require('erde.lib')

return {
  compile = require('erde.compile'),
  rewrite = lib.rewrite,
  traceback = lib.traceback,
  run = lib.runString,
  load = lib.load,
  unload = lib.unload,
}
