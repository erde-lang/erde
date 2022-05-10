-- -----------------------------------------------------------------------------
-- Newlines
-- -----------------------------------------------------------------------------

describe('Newlines', function()
  spec('statement newlines', function()
    assert.formatted(
      [[
break

break
]],
      [[
break

break
]]
    )
  end)
  spec('comment newlines', function()
    assert.formatted(
      [[
break

-- hello
break
]],
      [[
break

-- hello
break
]]
    )
  end)
  spec('comment + statement newlines', function()
    assert.formatted(
      [[
break

-- hello

break
]],
      [[
break

-- hello

break
]]
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Comments
-- -----------------------------------------------------------------------------

describe('Comments', function()
  spec('leading comments', function()
    assert.formatted(
      [[
-- a
break
]],
      [[
-- a
break
]]
    )
  end)
  spec('trailing comments', function()
    assert.formatted(
      [[
break
-- a
]],
      [[
break
-- a
]]
    )
  end)
  spec('inline comments', function()
    assert.formatted(
      [[
break -- a
]],
      [[
break -- a
]]
    )
  end)
  spec('orphaned comments', function()
    assert.formatted(
      [[
do --a
{   --c
  break --test2
}
]],
      [[
-- a
do { -- c
  break -- test2
}
]]
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Break / Continue / Goto
-- -----------------------------------------------------------------------------

spec('Break / Continue', function()
  assert.formatted(' break ', 'break')
  assert.formatted(' continue ', 'continue')
end)

spec('Goto', function()
  assert.formatted(' goto   blah ', 'goto blah')
  assert.formatted('::   blah ::', ' ::blah:: ')
end)

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

spec('IfElse', function()
    assert.formatted(
      [[
   if test 
   { 
}
]],
      [[
if test {

}
]]
    )
    assert.formatted(
      [[
   if test1
   { 
} elseif test2 {}
]],
      [[
if test1 {

} elseif test2 {

}
]]
    )
    assert.formatted(
      [[
   if test1
   { 
} elseif test2 {} elseif
test3{}
]],
      [[
if test1 {

} elseif test2 {

} elseif test3 {

}
]]
    )
    assert.formatted(
      [[
   if test 
   { 
} elseif test {}
else{}
]],
      [[
if test {

} elseif test {

} else {

}
]]
    )
    assert.formatted(
      [[
   if test 
   { }
else{}
]],
      [[
if test {

} else {

}
]]
    )
end)
