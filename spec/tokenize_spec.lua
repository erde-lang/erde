local tokenize = require('erde.compile.tokenize')
local CC = require('erde.compile.constants')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function assert_token(token, expected)
  local tokens = tokenize(token)
  assert.are.equal(expected or token, tokens[1])
end

local function assert_tokens(text, expected)
  local tokens = tokenize(text)
  assert.subtable(expected, tokens)
end

local function assert_token_lines(text, expected)
  local tokens, token_lines = tokenize(text)
  assert.subtable(expected, token_lines)
end

-- -----------------------------------------------------------------------------
-- Tests
-- -----------------------------------------------------------------------------

spec('symbols #5.1+', function()
  for symbol in pairs(CC.SYMBOLS) do
    assert_token(symbol)
  end
end)

spec('words #5.1+', function()
  assert_token('lua')
  assert_token('Erde')
  assert_token('_test')
  assert_token('aa1B_')
  assert_token('_aa1B')
  assert_tokens('a-', { 'a', '-' })
  assert_tokens('1abc', { '1', 'abc' })
end)

describe('hex', function()
  spec('#5.1+', function()
    assert_token('0x1', '1')
    assert_token('0X1', '1')
    assert_token('0x123456789', '4886718345')
    assert_token('0xabcdef', '11259375')
    assert_token('0xABCDEF', '11259375')
    assert_token('0xa1B2', '41394')
    assert_token('0x.1', '0.0625')
    assert_token('0xd.a', '13.625')
    assert_token('0xfp-2', '3.75')
    assert_tokens('0xf.', { '15', '.' })

    assert.has_error(function() tokenize('0x') end)
    assert.has_error(function() tokenize('0xg') end)
    assert.has_error(function() tokenize('0x.') end)
    assert.has_error(function() tokenize('0x.g') end)
    assert.has_error(function() tokenize('0x.p1') end)
    assert.has_error(function() tokenize('0xfp') end)
    assert.has_error(function() tokenize('0xfp+') end)
    assert.has_error(function() tokenize('0xfp-') end)
    assert.has_error(function() tokenize('0xfpa') end)
  end)

  spec('#5.1 #5.2 #jit', function()
    assert_token('0xfp1', '30')
    assert_token('0xfP1', '30')
    assert_token('0xfp+2', '60')
  end)

  spec('#5.3+', function()
    assert_token('0xfp1', '30.0')
    assert_token('0xfP1', '30.0')
    assert_token('0xfp+2', '60.0')
  end)
end)

spec('decimal #5.1+', function()
  assert_token('9')
  assert_token('43')
  assert_token('.34')
  assert_token('0.3')
  assert_token('1e2')
  assert_token('1E2')
  assert_token('3e+2')
  assert_token('3e-2')
  assert_token('1.23e29')

  assert.has_error(function() tokenize('9e') end)
  assert.has_error(function() tokenize('9e+') end)
  assert.has_error(function() tokenize('9e-') end)
end)

describe('binary', function()
  spec('#5.1+', function()
    assert_token('0b0', '0')
    assert_token('0B0', '0')
    assert_token('0b1', '1')
    assert_token('0B1', '1')
    assert_token('0b0100', '4')
    assert_token('0B1100', '12')

    assert.has_error(function() tokenize('0b') end)
    assert.has_error(function() tokenize('0B') end)
    assert.has_error(function() tokenize('0b3') end)
    assert.has_error(function() tokenize('0Ba') end)
    assert.has_error(function() tokenize('0b.') end)
  end)
end)

describe('escape chars', function()
  spec('#5.1+', function()
    for escapeChar in pairs(CC.STANDARD_ESCAPE_CHARS) do
      assert_tokens("'\\" .. escapeChar .. "'", { "'", '\\' .. escapeChar, "'" })
      assert_tokens('"\\' .. escapeChar .. '"', { '"', '\\' .. escapeChar, '"' })
      assert_tokens('[[\\' .. escapeChar .. ']]', { '[[', '\\' .. escapeChar, ']]' })
    end

    assert_tokens('"\\{"', { '"', '{', '"' })
    assert_tokens('"\\123"', { '"', '\\123', '"' })

    -- Erde does not allow for interpolation in single quote strings
    assert.has_error(function() tokenize("'\\{'") end)

    -- Lua 5.2+ single / double quote strings will throw for unrecognized escape sequences
    assert.has_error(function() tokenize("'\\o'") end)

    -- Lua does not process escape sequences in block strings
    assert_tokens('[[\\o]]', { '[[', '\\o', ']]' })
    assert_tokens('[[\\n]]', { '[[', '\\n', ']]' })
    assert_tokens('[[\\x]]', { '[[', '\\x', ']]' })
  end)

  spec('#jit #5.2+', function()
    assert_tokens('"\\z"', { '"', '\\z', '"' })
    assert_tokens('"\\x1f"', { '"', '\\x1f', '"' })

    assert.has_error(function() tokenize('"\\xA"') end)
    assert.has_error(function() tokenize('"\\x1G"') end)
  end)

  spec('#5.1', function()
    assert.has_error(function() tokenize('"\\z"') end)
    assert.has_error(function() tokenize('"\\x1f"') end)
  end)

  spec('#jit #5.3+', function()
    assert_tokens('"\\u{a}"', { '"', '\\u{a}', '"' })
    assert_tokens('"\\u{abc}"', { '"', '\\u{abc}', '"' })

    assert.has_error(function() tokenize('"\\uabc"') end)
    assert.has_error(function() tokenize('"\\u{abc"') end)
    assert.has_error(function() tokenize('"\\uabc}"') end)
    assert.has_error(function() tokenize('"\\u{}"') end)
    assert.has_error(function() tokenize('"\\u{g}"') end)
  end)

  spec('#5.1 #5.2', function()
    assert.has_error(function() tokenize('"\\u{a}"') end)
    assert.has_error(function() tokenize('"\\u{abc}"') end)
  end)
end)

spec('interpolation #5.1+', function()
  assert_tokens("'a{bc}d'", { "'", 'a{bc}d', "'" })
  assert_tokens('"a{bc}d"', { '"', 'a', '{', 'bc', '}', 'd', '"' })
  assert_tokens('"a{ bc  }d"', { '"', 'a', '{', 'bc', '}', 'd', '"' })
  assert_tokens('[[a{bc}d]]', { '[[', 'a', '{', 'bc', '}', 'd', ']]' })
  assert_tokens('[[a{{bc}}d]]', { '[[', 'a', '{', '{', 'bc', '}', '}', 'd', ']]' })

  assert.has_error(function() tokenize('"hello world {2"') end)
  assert.has_error(function() tokenize('"hello {2 world"') end)
end)

spec('single quote strings #5.1+', function()
  assert_tokens("''", { "'", "'" })
  assert_tokens("'hello world'", { "'", 'hello world', "'" })
  assert_tokens("' hello world '", { "'", ' hello world ', "'" })

  assert.has_error(function() tokenize("'hello") end)
  assert.has_error(function() tokenize("'hello\nworld'") end)
end)

spec('double quote strings #5.1+', function()
  assert_tokens('""', { '"', '"' })
  assert_tokens('"hello world"', { '"', 'hello world', '"' })
  assert_tokens('" hello world "', { '"', ' hello world ', '"' })

  assert.has_error(function() tokenize('"hello') end)
  assert.has_error(function() tokenize('"hello\nworld"') end)
end)

spec('block strings #5.1+', function()
  assert_tokens('[[]]', { '[[', ']]' })
  assert_tokens('[[ hello world ]]', { '[[', ' hello world ', ']]' })
  assert_tokens('[[hello\nworld]]', { '[[', 'hello\nworld', ']]' })
  assert_tokens('[=[hello[[world]=]', { '[=[', 'hello[[world', ']=]' })

  assert.has_error(function() tokenize('[[hello world') end)
  assert.has_error(function() tokenize('[[hello world]=]') end)
  assert.has_error(function() tokenize('[=[hello world]]') end)
end)

spec('comments #5.1+', function()
  assert.are.equal(0, #tokenize('--hello world'))
  assert.are.equal(0, #tokenize('-- hello world'))
  assert.are.equal(0, #tokenize('--[[hello world]] '))
  assert.are.equal(0, #tokenize('--[[ hello world ]] '))
  assert.are.equal(0, #tokenize('--[[hello\nworld]] '))
  assert.are.equal(0, #tokenize('--[[ hello world ]] '))
  assert.are.equal(0, #tokenize('--[=[hello ]]]=] '))
  assert.are.equal(3, #tokenize('x + --[[hi]] 4'))
  assert_tokens('--hello\nworld', { 'world' })
  assert_tokens('-- [[hello\nworld]]', { 'world', ']', ']' })

  assert.has_error(function() tokenize('--[[hello world') end)
  assert.has_error(function() tokenize('--[[hello world]=]') end)
  assert.has_error(function() tokenize('--[=[hello world]]') end)
end)

spec('token_lines #5.1+', function()
  assert_token_lines('a\nb', { 1, 2 })
  assert_token_lines('hello world\ngoodbye world', { 1, 1, 2, 2 })
end)
