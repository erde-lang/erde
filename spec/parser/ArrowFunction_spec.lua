local unit = require('erde.parser.unit')

spec('arrow function rule', function()
  assert.are.equal('ArrowFunction', unit.ArrowFunction('() -> {}').rule)
end)

spec('skinny arrow function', function()
  assert.has_subtable({
    variant = 'skinny',
    body = { { rule = 'Return' } },
  }, unit.ArrowFunction(
    '() -> { return 1 }'
  ))
end)

spec('fat arrow function', function()
  assert.has_subtable({
    variant = 'fat',
    body = { { rule = 'Return' } },
  }, unit.ArrowFunction(
    '() => { return 1 }'
  ))
end)

spec('arrow function implicit return', function()
  assert.has_subtable({
    hasImplicitReturns = true,
    returns = { { value = '1' } },
  }, unit.ArrowFunction(
    '() -> 1'
  ))
  assert.has_subtable({
    hasImplicitReturns = true,
    returns = {
      { value = '1' },
      { value = '2' },
    },
  }, unit.ArrowFunction(
    '() => 1, 2'
  ))
  assert.has_error(function()
    unit.ArrowFunction('() ->')
  end)
end)

spec('arrow function implicit params', function()
  assert.has_subtable({
    hasImplicitParams = true,
    params = { value = 'a' },
  }, unit.ArrowFunction(
    'a -> {}'
  ))
  assert.has_error(function()
    unit.ArrowFunction('a.b -> {}')
  end)
end)
