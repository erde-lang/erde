local tokenize = require('erde.tokenize')

-- TODO: more tests
--
-- words
-- integer
-- float
-- hex
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

describe('Tokenizer', function()
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
