spec('break / continue', function()
  assert.formatted(' break ', 'break')
  assert.formatted(' continue ', 'continue')
end)

spec('goto', function()
  assert.formatted(' goto   blah ', 'goto blah')
  assert.formatted('::   blah ::', ' ::blah:: ')
end)
