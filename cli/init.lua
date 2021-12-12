#!/usr/bin/env lua

local argparse = require('argparse')

-- -----------------------------------------------------------------------------
-- Setup
-- -----------------------------------------------------------------------------

local cli = argparse('erde')
cli:add_complete()

local compile = cli:command('compile')
compile:argument('input', 'Input file.')

local run = cli:command('run')
local format = cli:command('format')

-- -----------------------------------------------------------------------------
-- Process
-- -----------------------------------------------------------------------------

local args = cli:parse()
