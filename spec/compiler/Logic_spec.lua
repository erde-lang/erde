local erde = require('erde')

local function run(erdecode)
  return (loadstring or load)(erde.compile(erdecode))()
end

spec('if else', function()
  assert.are.equal(1, run('if true { return 1 }'))
  assert.are.equal('if true then  elseif true then  end', erde.compile('if true {} elseif true {}'))
  assert.are.equal('if true then  else  end', erde.compile('if true {} else {}'))
end)
