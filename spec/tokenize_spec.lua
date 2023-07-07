local C = require('erde.constants')
local tokenize = require('erde.tokenize')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function assert_token(expected, token)
  local tokens = tokenize(token or expected)
  assert.are.equal(expected, tokens[1].value)
end

local function assert_tokens(expected, text)
  local token_values = {}

  for _, token in ipairs(tokenize(text)) do
    table.insert(token_values, token.value)
  end

  assert.are.same(expected, token_values)
end

local function assert_num_tokens(expected, text)
  local tokens = tokenize(text)
  assert.are.equal(expected, #tokens)
end

-- -----------------------------------------------------------------------------
-- Number Tokenizers
-- -----------------------------------------------------------------------------

spec('tokenize_binary #5.1+', function()
  assert_token('0', '0b0')
  assert_token('0', '0B0')
  assert_token('1', '0b1')
  assert_token('1', '0B1')

  assert_token('0', '0b00')
  assert_token('1', '0b01')
  assert_token('2', '0b10')
  assert_token('4', '0b0100')
  assert_token('12', '0B1100')

  assert.has_error(function() tokenize('0b') end)
  assert.has_error(function() tokenize('0B') end)
  assert.has_error(function() tokenize('0b3') end)
  assert.has_error(function() tokenize('0ba') end)
  assert.has_error(function() tokenize('0b.') end)
end)

spec('tokenize_decimal #5.1+', function()
  for i = 1, 9 do
    assert_token(tostring(i))
  end

  assert_token('123')
  assert_token('12300')
  assert_token('00123')
  assert_token('0012300')

  assert_token('.0')
  assert_token('0.0')
  assert_token('.123')
  assert_token('0.001')
  assert_token('0.100')
  assert_token('0.010')
  assert_token('9.87')

  assert_tokens({ '0', '.' }, '0.')
  assert_tokens({ '0', '.', 'e' }, '0.e')

  assert_token('1e2')
  assert_token('1E2')
  assert_token('1e+2')
  assert_token('1e-2')
  assert_token('1E+2')
  assert_token('1E-2')

  assert_token('1.23e29')
  assert_token('0.11E-39')

  assert.has_error(function() tokenize('9e') end)
  assert.has_error(function() tokenize('9e+') end)
  assert.has_error(function() tokenize('9e-') end)
end)

describe('tokenize_hex', function()
  spec('#5.1+', function()
    assert_token('1', '0x1')
    assert_token('1', '0X1')

    assert_token('4886718345', '0x123456789')
    assert_token('11259375', '0xabcdef')
    assert_token('11259375', '0xABCDEF')
    assert_token('41394', '0xa1B2')

    assert_token('0.0625', '0x.1')
    assert_token('13.625', '0xd.a')

    assert_token('3.75', '0xfp-2')
    assert_tokens({ '15', '.' }, '0xf.')

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
    assert_token('30', '0xfp1')
    assert_token('30', '0xfP1')
    assert_token('60', '0xfp+2')
  end)

  spec('#5.3+', function()
    assert_token('30.0', '0xfp1')
    assert_token('30.0', '0xfP1')
    assert_token('60.0', '0xfp+2')
  end)
end)

-- -----------------------------------------------------------------------------
-- String Tokenizers
-- -----------------------------------------------------------------------------

describe('tokenize_escape_sequence', function()
  spec('#5.1+', function()
    for escapeChar in pairs(C.STANDARD_ESCAPE_CHARS) do
      assert_tokens({ '\\' .. escapeChar }, "'\\" .. escapeChar .. "'")
      assert_tokens({ '"', '\\' .. escapeChar, '"' }, '"\\' .. escapeChar .. '"')
    end

    assert_tokens({ '\\1' }, "'\\1'")
    assert_tokens({ '\\123' }, "'\\123'")
    assert_tokens({ '"', '\\1', '"' }, '"\\1"')
    assert_tokens({ '"', '\\123', '"' }, '"\\123"')

    -- Lua 5.2+ will throw an error for unrecognized escape sequences
    assert.has_error(function() tokenize("'\\o'") end)
    assert.has_error(function() tokenize('"\\o"') end)
    assert.has_no.error(function() tokenize('[[\\o]]') end)

    -- Erde does not allow for interpolation in single quote strings
    assert.has_error(function() tokenize("'\\{'") end)
    assert.has_no.error(function() tokenize('"\\{"') end)
    assert.has_no.error(function() tokenize('[[\\{]]') end)

    -- Lua does not process escape sequences in block strings
    assert.has_no.error(function() tokenize('[[\\x]]') end)
    assert.has_no.error(function() tokenize('[[\\u]]') end)
  end)

  spec('#5.1', function()
    assert.has_error(function() tokenize('"\\z"') end)
    assert.has_error(function() tokenize('"\\x1f"') end)
  end)

  spec('#5.1 #5.2', function()
    assert.has_error(function() tokenize('"\\u{a}"') end)
    assert.has_error(function() tokenize('"\\u{abc}"') end)
  end)

  spec('#jit #5.2+', function()
    assert_tokens({ '"', '\\z', '"' }, '"\\z"')
    assert_tokens({ '"', '\\x1f', '"' }, '"\\x1f"')

    assert.has_error(function() tokenize('"\\xA"') end)
    assert.has_error(function() tokenize('"\\x1G"') end)
  end)

  spec('#jit #5.3+', function()
    assert_tokens({ '"', '\\u{a}', '"' }, '"\\u{a}"')
    assert_tokens({ '"', '\\u{abc}', '"' }, '"\\u{abc}"')

    assert.has_error(function() tokenize('"\\uabc"') end)
    assert.has_error(function() tokenize('"\\u{abc"') end)
    assert.has_error(function() tokenize('"\\uabc}"') end)
    assert.has_error(function() tokenize('"\\u{}"') end)
    assert.has_error(function() tokenize('"\\u{g}"') end)
  end)
end)

spec('tokenize_interpolation #5.1+', function()
  assert_tokens({ 'a{bc}d' }, "'a{bc}d'")
  assert_tokens({ '"', 'a', '{', 'bc', '}', 'd', '"' }, '"a{bc}d"')
  assert_tokens({ '[[', 'a', '{', 'bc', '}', 'd', ']]' }, '[[a{bc}d]]')

  assert_tokens({ 'a{ bc  }d' }, "'a{ bc  }d'")
  assert_tokens({ '"', 'a', '{', 'bc', '}', 'd', '"' }, '"a{ bc  }d"')
  assert_tokens({ '[[', 'a', '{', 'bc', '}', 'd', ']]' }, '[[a{ bc  }d]]')

  assert_tokens({ '"', '{', '"', '{', 'a', '}', '"', '}', '"' }, '"{"{a}"}"')
  assert_tokens({ '[[', 'a', '{', '{', 'bc', '}', '}', 'd', ']]' }, '[[a{{bc}}d]]')

  assert.has_error(function() tokenize('"{a"') end)
  assert.has_error(function() tokenize('"{{a}"') end)
end)

spec('tokenize_single_quote_string #5.1+', function()
  assert_tokens({ '' }, "''")
  assert_tokens({ ' ' }, "' '")
  assert_tokens({ '\t' }, "'\t'")

  assert_tokens({ 'a' }, "'a'")
  assert_tokens({ ' a b ' }, "' a b '")

  assert_tokens({ "\\'" }, "'\\''")
  assert_tokens({ '\\n' }, "'\\n'")

  assert.has_error(function() tokenize("'a") end)
  assert.has_error(function() tokenize("'\n'") end)
end)

spec('tokenize_double_quote_string #5.1+', function()
  assert_tokens({ '"', '"' }, '""')
  assert_tokens({ '"', ' ', '"' }, '" "')
  assert_tokens({ '"', '\t', '"' }, '"\t"')

  assert_tokens({ '"', 'a', '"' }, '"a"')
  assert_tokens({ '"', ' a b ', '"' }, '" a b "')

  assert_tokens({ '"', '\\"', '"' }, '"\\""')
  assert_tokens({ '"', '\\n', '"' }, '"\\n"')

  assert_tokens({ '"', '{a}', '"' }, '"\\{a}"')
  assert_tokens({ '"', '{a}', '"' }, '"\\{a\\}"')
  assert_tokens({ '"', '{', 'a', '}', '"' }, '"{a}"')

  assert.has_error(function() tokenize('"a') end)
  assert.has_error(function() tokenize('"\n"') end)
end)

spec('tokenize_block_string #5.1+', function()
  assert_tokens({ '[[', ']]' }, '[[]]')
  assert_tokens({ '[[', ' ', ']]' }, '[[ ]]')
  assert_tokens({ '[[', '\t', ']]' }, '[[\t]]')
  assert_tokens({ '[[', '\n', ']]' }, '[[\n]]')

  assert_tokens({ '[[', ' hello world ', ']]' }, '[[ hello world ]]')
  assert_tokens({ '[[', 'hello\nworld', ']]' }, '[[hello\nworld]]')

  assert_tokens({ '[[', '[=[', ']]' }, '[[[=[]]')
  assert_tokens({ '[[', ']=', ']]' }, '[[]=]]')
  assert_tokens({ '[=[', '[[', ']=]' }, '[=[[[]=]')
  assert_tokens({ '[=[', ']]', ']=]' }, '[=[]]]=]')

  assert_tokens({ '[[', '\\', ']]' }, '[[\\]]')
  assert_tokens({ '[[', '\\u', ']]' }, '[[\\u]]')

  assert_tokens({ '[[', '{a}', ']]' }, '[[\\{a}]]')
  assert_tokens({ '[[', '{a}', ']]' }, '[[\\{a\\}]]')
  assert_tokens({ '[[', '{', 'a', '}', ']]' }, '[[{a}]]')

  assert.has_error(function() tokenize('[=hello world]=]') end)
  assert.has_error(function() tokenize('[[hello world') end)
  assert.has_error(function() tokenize('[[hello world]=]') end)
  assert.has_error(function() tokenize('[=[hello world]]') end)
end)

-- -----------------------------------------------------------------------------
-- Misc Tokenizers
-- -----------------------------------------------------------------------------

spec('tokenize symbols #5.1+', function()
  for symbol in pairs(C.SYMBOLS) do
    assert_token(symbol)
  end
end)

spec('tokenize_word #5.1+', function()
  assert_token('lua')
  assert_token('Erde')
  assert_token('_test')
  assert_token('aa1B_')
  assert_token('_aa1B')

  assert_tokens({ 'a', '-' }, 'a-')
  assert_tokens({ '1', 'abc' }, '1abc')
end)

spec('tokenize_comment #5.1+', function()
  assert_num_tokens(1, '--')
  assert_num_tokens(1, '--a')
  assert_num_tokens(1, '-- a')
  assert_num_tokens(2, '--\na')
  assert_num_tokens(2, '--a\nb')

  assert_num_tokens(2, '--[=a\nb')
  assert_num_tokens(2, '-- [[a\nb')

  assert_num_tokens(1, '--[[a]]')
  assert_num_tokens(1, '--[[ a ]]')
  assert_num_tokens(1, '--[[a\nb]]')
  assert_num_tokens(2, '--[[a]]b')

  assert_num_tokens(1, '--[[[=[]]')
  assert_num_tokens(1, '--[[]=]]')
  assert_num_tokens(1, '--[=[[[]=]')
  assert_num_tokens(1, '--[=[]]]=]')

  assert_num_tokens(2, '-- [[a\nb')
  assert_num_tokens(4, 'x + --[[hi]] 4')

  assert.has_error(function() tokenize('--[[hello world') end)
  assert.has_error(function() tokenize('--[[hello world]=]') end)
  assert.has_error(function() tokenize('--[=[hello world]]') end)
end)
