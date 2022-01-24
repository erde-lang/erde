local tokenize = require('erde.tokenize')

-- TODO: more tests

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
