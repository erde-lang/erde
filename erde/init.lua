local loader = require('erde.loader')

return {
  load = loader.load,
  unload = loader.unload,
  compile = require('erde.compile'),
  run = require('erde.run').string,
  debug = require('erde.debug'),
}
