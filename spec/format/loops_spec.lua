spec('numeric for', function()
  assert.formatted(
    [[
    for i = a  ,  b
   { 
}
]],
    [[
for i = a, b {

}
]]
  )
  assert.formatted(
    [[
    for  i    = a,   b,c
   { 
}
]],
    [[
for i = a, b, c {

}
]]
  )
end)

spec('generic for', function()
  assert.formatted(
    [[
    for a   in    A
   { 
}
]],
    [[
for a in A {

}
]]
  )
  assert.formatted(
    [[
    for a,    b, c  in  A,B,C
   { 
}
]],
    [[
for a, b, c in A, B, C {

}
]]
  )
end)

spec('while loop', function()
  assert.formatted(
    [[
    while   someCondition
   { 
}
]],
    [[
while someCondition {

}
]]
  )
end)

spec('repeat until', function()
  assert.formatted(
    [[
    repeat
   { 
} until   
a
]],
    [[
repeat {

} until a
]]
  )
end)
