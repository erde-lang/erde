local tokenize = require('erde.tokenize')
local C = require('erde.constants')

local function getToken(text, i)
  i = i or 1
  return tokenize(text).tokens[i]
end

local function getTokens(text)
  return tokenize(text).tokens
end

-- TODO: more tests
--
-- short comments
-- long comments
-- tokenInfo (line / column numbers)

describe('tokenize', function()
  spec('symbols', function()
    for symbol in pairs(C.SYMBOLS) do
      assert.are.equal(symbol, getToken(symbol))
    end
  end)

  describe('word', function()
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

  describe('number', function()
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

  describe('string', function()
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

  describe('comment', function()
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
        tokenize('--[[ hello world ]]').comments
      )
    end)
  end)
end)
