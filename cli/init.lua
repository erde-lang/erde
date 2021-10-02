#!/usr/bin/env lua

local argparse = require('argparse')

local parser = argparse('erde')
parser:add_complete()
parser:argument('input', 'Input file.')
parser:option('-o --output', 'Output file.', 'a.out')

parser:command('compile')
parser:command('run')
parser:command('format')

local args = parser:parse()
