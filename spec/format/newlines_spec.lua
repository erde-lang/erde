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
