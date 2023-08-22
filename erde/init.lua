local lib = require("erde.lib")
local VERSION
local __ERDE_TMP_4__ = require("erde.constants")
VERSION = __ERDE_TMP_4__.VERSION
return {
	version = VERSION,
	compile = require("erde.compile"),
	rewrite = lib.rewrite,
	traceback = lib.traceback,
	run = lib.run,
	load = lib.load,
	unload = lib.unload,
}
-- Compiled with Erde 1.0.0-1 w/ Lua target 5.1+
-- __ERDE_COMPILED__
