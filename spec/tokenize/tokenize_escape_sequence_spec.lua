local CC = require('erde.compile.constants')
local tokenize = require('erde.tokenize')

local spec_utils = require('spec.utils')
local assert_tokens = spec_utils.assert_tokens

describe('tokenize_escape_sequence', function()
  spec('#5.1+', function()
    for escapeChar in pairs(CC.STANDARD_ESCAPE_CHARS) do
      assert_tokens({ "'", '\\' .. escapeChar, "'" }, "'\\" .. escapeChar .. "'")
      assert_tokens({ '"', '\\' .. escapeChar, '"' }, '"\\' .. escapeChar .. '"')
    end

    assert_tokens({ "'", '\\1', "'" }, "'\\1'")
    assert_tokens({ "'", '\\123', "'" }, "'\\123'")
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
