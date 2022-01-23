local tokenize = require('erde.tokenize')

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
