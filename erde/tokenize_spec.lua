local tokenize = require('erde.tokenize')

-- TODO: more tests
--
-- operator symbol
-- other symbols (ex. arrow function)
-- single quote string
-- double quote string
-- long string
-- short comments
-- long comments
-- newlines
-- single char symbols
-- whitespace
--
-- tokenInfo (line / column numbers)

describe('tokenize', function()
  describe('word', function()
    spec('word head', function()
      assert.are.equal('lua', tokenize('lua')[1])
      assert.are.equal('Erde', tokenize('Erde')[1])
      assert.are.equal('_test', tokenize('_test')[1])
      assert.has_error(function()
        tokenize('1word')
      end)
    end)

    spec('word body', function()
      assert.are.equal('aa1B_', tokenize('aa1B_')[1])
      assert.are.equal('a', tokenize('a-')[1])
    end)
  end)

  describe('number', function()
    describe('hex', function()
      spec('integer', function()
        assert.are.equal('0x123456789', tokenize('0x123456789')[1])
        assert.are.equal('0xabcdef', tokenize('0xabcdef')[1])
        assert.are.equal('0xABCDEF', tokenize('0xABCDEF')[1])
        assert.are.equal('0xa1B2', tokenize('0xa1B2')[1])

        assert.are.equal('0x1', tokenize('0x1')[1])
        assert.are.equal('0X1', tokenize('0X1')[1])

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
        assert.are.equal('0x.1', tokenize('0x.1')[1])
        assert.are.equal('0xd.a', tokenize('0xd.a')[1])
        assert.are.equal('0xfp1', tokenize('0xfp1')[1])
        assert.are.equal('0xfP1', tokenize('0xfP1')[1])
        assert.are.equal('0xfp+1', tokenize('0xfp+1')[1])
        assert.are.equal('0xfp-1', tokenize('0xfp-1')[1])

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
        assert.are.equal('9', tokenize('9')[1])
        assert.are.equal('43', tokenize('43')[1])
      end)

      spec('float', function()
        assert.are.equal('.34', tokenize('.34')[1])
        assert.are.equal('0.3', tokenize('0.3')[1])
        assert.are.equal('1e2', tokenize('1e2')[1])
        assert.are.equal('1E2', tokenize('1E2')[1])
        assert.are.equal('3e+2', tokenize('3e+2')[1])
        assert.are.equal('3e-2', tokenize('3e-2')[1])
        assert.are.equal('1.23e29', tokenize('1.23e29')[1])

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

  spec('symbols', function()
    assert.has_subtable({
      '(',
      ')',
      '->',
      'x',
    }, tokenize(
      '() -> x'
    ))
  end)
end)
