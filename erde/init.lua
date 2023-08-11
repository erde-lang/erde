local lib = require("erde.lib")
local VERSION
do
	local __ERDE_TMP_4__
	__ERDE_TMP_4__ = require("erde.constants")
	VERSION = __ERDE_TMP_4__["VERSION"]
end
return {
	version = VERSION,
	compile = require("erde.compile"),
	rewrite = lib.rewrite,
	traceback = lib.traceback,
	run = lib.run,
	load = lib.load,
	unload = lib.unload,
}
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
