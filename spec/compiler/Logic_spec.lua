local erde = require('erde')

spec('if else', function()
  assert.are.equal('if true then local x = 1 end', erde.compile('if true { local x = 1 }'))
  assert.are.equal('if true then  elseif true then  end', erde.compile('if true {} elseif true {}'))
  assert.are.equal('if true then  else  end', erde.compile('if true {} else {}'))
end)
