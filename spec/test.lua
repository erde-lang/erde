package.path = '/home/bsuth/projects/luascript/src/?.lua;' .. package.path

local inspect = require('inspect')
local ls = require('compiler')

ls.compile('test_input.ls', 'test_input.lua')
