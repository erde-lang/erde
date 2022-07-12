local loader = require('erde.loader')

return {
  -- TODO: REMOVE
  debugCompile = require('erde.debugCompile'),
  load = loader.load,
  unload = loader.unload,
  compile = require('erde.compile'),
  run = require('erde.run'),
}
