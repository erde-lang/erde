describe('Comments', function()
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
