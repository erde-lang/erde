local tokenize = require('erde.tokenize')
local C = require('erde.constants')

local function getToken(text, i)
  i = i or 1
  return tokenize(text).tokens[i]
end

local function getTokens(text)
  return tokenize(text).tokens
end

describe('tokenize', function()
  spec('symbols', function()
    for symbol in pairs(C.SYMBOLS) do
      assert.are.equal(symbol, getToken(symbol))
    end
  end)

  describe('words', function()
    spec('word head', function()
      assert.are.equal('lua', getToken('lua'))
      assert.are.equal('Erde', getToken('Erde'))
      assert.are.equal('_test', getToken('_test'))
      assert.has_error(function()
        tokenize('1word')
      end)
    end)

    spec('word body', function()
      assert.are.equal('aa1B_', getToken('aa1B_'))
      assert.are.equal('a', getToken('a-'))
    end)
  end)

  describe('numbers', function()
    describe('hex', function()
      spec('integer', function()
        assert.are.equal('0x123456789', getToken('0x123456789'))
        assert.are.equal('0xabcdef', getToken('0xabcdef'))
        assert.are.equal('0xABCDEF', getToken('0xABCDEF'))
        assert.are.equal('0xa1B2', getToken('0xa1B2'))

        assert.are.equal('0x1', getToken('0x1'))
        assert.are.equal('0X1', getToken('0X1'))

        assert.has_error(function()
          tokenize('1x3')
        end)
        assert.has_error(function()
          tokenize('0x')
        end)
        assert.has_error(function()
          tokenize('0xg')
        end)
      end)

      spec('float', function()
        assert.are.equal('0x.1', getToken('0x.1'))
        assert.are.equal('0xd.a', getToken('0xd.a'))
        assert.are.equal('0xfp1', getToken('0xfp1'))
        assert.are.equal('0xfP1', getToken('0xfP1'))
        assert.are.equal('0xfp+1', getToken('0xfp+1'))
        assert.are.equal('0xfp-1', getToken('0xfp-1'))

        assert.has_error(function()
          tokenize('0x.')
        end)
        assert.has_error(function()
          tokenize('0x.p1')
        end)
        assert.has_error(function()
          tokenize('0xfp+')
        end)
        assert.has_error(function()
          tokenize('0xfp-')
        end)
        assert.has_error(function()
          tokenize('0xfpa')
        end)
      end)
    end)

    describe('decimal', function()
      spec('integer', function()
        assert.are.equal('9', getToken('9'))
        assert.are.equal('43', getToken('43'))
      end)

      spec('float', function()
        assert.are.equal('.34', getToken('.34'))
        assert.are.equal('0.3', getToken('0.3'))
        assert.are.equal('1e2', getToken('1e2'))
        assert.are.equal('1E2', getToken('1E2'))
        assert.are.equal('3e+2', getToken('3e+2'))
        assert.are.equal('3e-2', getToken('3e-2'))
        assert.are.equal('1.23e29', getToken('1.23e29'))

        assert.has_error(function()
          tokenize('4.')
        end)
        assert.has_error(function()
          tokenize('0.e1')
        end)
        assert.has_error(function()
          tokenize('9e')
        end)
        assert.has_error(function()
          tokenize('9e+')
        end)
        assert.has_error(function()
          tokenize('9e-')
        end)
      end)
    end)
  end)

  describe('strings', function()
    spec('single quote', function()
      assert.are.equal(2, #getTokens("''"))
      assert.subtable({ "'", 'hello', "'" }, getTokens("'hello'"))
      assert.subtable({ "'", 'a\\nb', "'" }, getTokens("'a\\nb'"))
      assert.subtable({ "'", '\\\\', "'" }, getTokens("'\\\\'"))

      assert.has_error(function()
        tokenize("'hello")
      end)
      assert.has_error(function()
        tokenize("'hello\nworld'")
      end)
    end)

    spec('double quote', function()
      assert.are.equal(2, #getTokens('""'))
      assert.subtable({ '"', 'hello', '"' }, getTokens('"hello"'))
      assert.subtable(
        { '"', 'hello\\nworld', '"' },
        getTokens('"hello\\nworld"')
      )
      assert.subtable({ '"', '\\\\', '"' }, getTokens('"\\\\"'))

      assert.has_error(function()
        tokenize('"hello')
      end)
      assert.has_error(function()
        tokenize('"hello\nworld"')
      end)
    end)

    spec('long string', function()
      assert.subtable({ '[[', ' a b ', ']]' }, getTokens('[[ a b ]]'))
      assert.subtable({ '[[', 'a\nb', ']]' }, getTokens('[[a\nb]]'))
      assert.subtable({ '[=[', 'a[[b', ']=]' }, getTokens('[=[a[[b]=]'))

      assert.has_error(function()
        tokenize('[[hello world')
      end)
      assert.has_error(function()
        tokenize('[=hello world')
      end)
    end)

    spec('interpolation', function()
      assert.subtable({ "'", 'a{bc}d', "'" }, getTokens("'a\\{bc}d'"))
      assert.subtable({ '"', 'a{bc}d', '"' }, getTokens('"a\\{bc}d"'))
      assert.subtable({ '[[', 'a{bc}d', ']]' }, getTokens('[[a\\{bc}d]]'))

      assert.has_error(function()
        tokenize('"hello world {2"')
      end)
      assert.has_error(function()
        tokenize('"hello {2 world"')
      end)
    end)
  end)

  describe('comments', function()
    spec('short comment', function()
      assert.subtable(
        { { token = 'hello world' } },
        tokenize('--hello world').comments
      )
      assert.subtable(
        { { token = ' hello world' } },
        tokenize('-- hello world').comments
      )
      assert.subtable(
        { { token = 'hello' } },
        tokenize('--hello\nworld').comments
      )
    end)
    spec('long comment', function()
      assert.subtable(
        { { token = ' hello world ' } },
        tokenize('--[[ hello world ]] ').comments
      )
      assert.subtable(
        { { token = 'hello\nworld' } },
        tokenize('--[[hello\nworld]] ').comments
      )
      assert.subtable(
        { { eq = '', token = 'hello world' } },
        tokenize('--[[hello world]] ').comments
      )
      assert.subtable(
        { { eq = '=', token = 'hello ]]' } },
        tokenize('--[=[hello ]]]=] ').comments
      )
      assert.subtable(
        { { tokenIndex = 2 } },
        tokenize('x + --[[hi]] 4').comments
      )
    end)
  end)

  spec('newlines', function()
    assert.are.equal(1, tokenize('a\nb').newlines[1])
    assert.are.equal(nil, tokenize('a\nb').newlines[2])
    assert.are.equal(2, tokenize('a\n\nb').newlines[1])
    assert.subtable({ 'a', 'b' }, getTokens('a\n\nb'))
  end)

  describe('tokenInfo', function()
    spec('tokenInfo', function()
      assert.subtable(
        { { line = 1 }, { line = 2 } },
        tokenize('a\nb').tokenInfo
      )
      assert.subtable(
        { { line = 1 }, { line = 1 }, { line = 2 }, { line = 2 } },
        tokenize('hello world\ngoodbye world').tokenInfo
      )
      assert.subtable(
        { { column = 1 }, { column = 1 } },
        tokenize('a\nb').tokenInfo
      )
      assert.subtable(
        { { column = 1 }, { column = 7 }, { column = 1 }, { column = 9 } },
        tokenize('hello world\ngoodbye world').tokenInfo
      )
    end)
  end)
end)
