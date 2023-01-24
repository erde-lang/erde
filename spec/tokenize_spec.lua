local tokenize = require('erde.tokenize')
local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function assertToken(token)
  local tokens = tokenize(token)
  assert.are.equal(token, tokens[1])
end

local function assertTokens(text, expectedTokens)
  local tokens = tokenize(text)
  assert.subtable(expectedTokens, tokens)
end

local function assertTokenLines(text, expectedTokenLines)
  local tokens, tokenLines = tokenize(text)
  assert.subtable(expectedTokenLines, tokenLines)
end

-- -----------------------------------------------------------------------------
-- Tests
-- -----------------------------------------------------------------------------

spec('symbols #5.1+', function()
  for symbol in pairs(C.SYMBOLS) do
    assertToken(symbol)
  end
end)

spec('words #5.1+', function()
  assertToken('lua')
  assertToken('Erde')
  assertToken('_test')
  assertToken('aa1B_')
  assertToken('_aa1B')
  assertTokens('a-', { 'a', '-' })
  assertTokens('1abc', { '1', 'abc' })
end)

describe('hex', function()
  spec('#5.1+', function()
    assertToken('0x1')
    assertToken('0X1')
    assertToken('0x123456789')
    assertToken('0xabcdef')
    assertToken('0xABCDEF')
    assertToken('0xa1B2')
    assertToken('0xfp1')
    assertToken('0xfP1')
    assertTokens('0xf.', { '0xf', '.' })

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

  spec('#jit #5.2+', function()
    assertToken('0x.1')
    assertToken('0xd.a')
    assertToken('0xfp+1')
    assertToken('0xfp-1')
  end)

  spec('#5.1', function()
    assert.has_error(function() tokenize('0x.1') end)
    assert.has_error(function() tokenize('0xd.a') end)
    assert.has_error(function() tokenize('0xfp+1') end)
    assert.has_error(function() tokenize('0xfp-1') end)
  end)
end)

spec('decimal #5.1+', function()
  assertToken('9')
  assertToken('43')
  assertToken('.34')
  assertToken('0.3')
  assertToken('1e2')
  assertToken('1E2')
  assertToken('3e+2')
  assertToken('3e-2')
  assertToken('1.23e29')

  assert.has_error(function() tokenize('9e') end)
  assert.has_error(function() tokenize('9e+') end)
  assert.has_error(function() tokenize('9e-') end)
end)

describe('binary', function()
  spec('#jit', function()
    assertToken('0b0')
    assertToken('0B0')
    assertToken('0b1')
    assertToken('0B1')
    assertToken('0b0100')
    assertToken('0B1100')

    assert.has_error(function() tokenize('0b') end)
    assert.has_error(function() tokenize('0B') end)
    assert.has_error(function() tokenize('0b3') end)
    assert.has_error(function() tokenize('0Ba') end)
    assert.has_error(function() tokenize('0b.') end)
  end)

  spec('#5.1 #5.2+', function()
    assert.has_error(function() tokenize('0b0') end)
    assert.has_error(function() tokenize('0B0') end)
    assert.has_error(function() tokenize('0b1') end)
    assert.has_error(function() tokenize('0B1') end)
    assert.has_error(function() tokenize('0b0100') end)
    assert.has_error(function() tokenize('0B1100') end)
  end)
end)

describe('escape chars', function()
  spec('#5.1+', function()
    for escapeChar in pairs(C.STANDARD_ESCAPE_CHARS) do
      assertTokens("'\\" .. escapeChar .. "'", { "'", '\\' .. escapeChar, "'" })
      assertTokens('"\\' .. escapeChar .. '"', { '"', '\\' .. escapeChar, '"' })
      assertTokens('[[\\' .. escapeChar .. ']]', { '[[', '\\' .. escapeChar, ']]' })
    end

    assertTokens('"\\{"', { '"', '{', '"' })
    assertTokens('"\\123"', { '"', '\\123', '"' })

    -- Erde does not allow for interpolation in single quote strings
    assert.has_error(function() tokenize("'\\{'") end)

    -- Lua 5.2+ single / double quote strings will throw for unrecognized escape chars
    assert.has_error(function() tokenize("'\\o'") end)

    -- Lua does not process escape chars in long strings
    assertTokens('[[\\o]]', { '[[', '\\o', ']]' })
    assertTokens('[[\\n]]', { '[[', '\\n', ']]' })
    assertTokens('[[\\x]]', { '[[', '\\x', ']]' })
  end)

  spec('#jit #5.2+', function()
    assertTokens('"\\z"', { '"', '\\z', '"' })
    assertTokens('"\\x1f"', { '"', '\\x1f', '"' })

    assert.has_error(function() tokenize('"\\xA"') end)
    assert.has_error(function() tokenize('"\\x1G"') end)
  end)

  spec('#5.1', function()
    assert.has_error(function() tokenize('"\\z"') end)
    assert.has_error(function() tokenize('"\\x1f"') end)
  end)

  spec('#jit #5.3+', function()
    assertTokens('"\\u{a}"', { '"', '\\u{a}', '"' })
    assertTokens('"\\u{abc}"', { '"', '\\u{abc}', '"' })

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
  assertTokens("'a{bc}d'", { "'", 'a{bc}d', "'" })
  assertTokens('"a{bc}d"', { '"', 'a', '{', 'bc', '}', 'd', '"' })
  assertTokens('"a{ bc  }d"', { '"', 'a', '{', 'bc', '}', 'd', '"' })
  assertTokens('[[a{bc}d]]', { '[[', 'a', '{', 'bc', '}', 'd', ']]' })
  assertTokens('[[a{{bc}}d]]', { '[[', 'a', '{', '{', 'bc', '}', '}', 'd', ']]' })

  assert.has_error(function() tokenize('"hello world {2"') end)
  assert.has_error(function() tokenize('"hello {2 world"') end)
end)

spec('single quote strings #5.1+', function()
  assertTokens("''", { "'", "'" })
  assertTokens("'hello world'", { "'", 'hello world', "'" })
  assertTokens("' hello world '", { "'", ' hello world ', "'" })

  assert.has_error(function() tokenize("'hello") end)
  assert.has_error(function() tokenize("'hello\nworld'") end)
end)

spec('double quote strings #5.1+', function()
  assertTokens('""', { '"', '"' })
  assertTokens('"hello world"', { '"', 'hello world', '"' })
  assertTokens('" hello world "', { '"', ' hello world ', '"' })

  assert.has_error(function() tokenize('"hello') end)
  assert.has_error(function() tokenize('"hello\nworld"') end)
end)

spec('long strings #5.1+', function()
  assertTokens('[[]]', { '[[', ']]' })
  assertTokens('[[ hello world ]]', { '[[', ' hello world ', ']]' })
  assertTokens('[[hello\nworld]]', { '[[', 'hello\nworld', ']]' })
  assertTokens('[=[hello[[world]=]', { '[=[', 'hello[[world', ']=]' })

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
  assertTokens('--hello\nworld', { 'world' })
  assertTokens('-- [[hello\nworld]]', { 'world', ']', ']' })

  assert.has_error(function() tokenize('--[[hello world') end)
  assert.has_error(function() tokenize('--[[hello world]=]') end)
  assert.has_error(function() tokenize('--[=[hello world]]') end)
end)

spec('tokenLines #5.1+', function()
  assertTokenLines('a\nb', { 1, 2 })
  assertTokenLines('hello world\ngoodbye world', { 1, 1, 2, 2 })
end)
