t[3, 5]::Iter () => {

}

test::Slice(3, 5)::Iter () => {

}

t::Iter () => {

}

const Yell = (x, y = 4, ...rest) => {
  []{4}::Iter () => {
    print "hello"
  }

  []:Loop (true, () => {
    print "infinite loop"
  })

  Regex /^[0-9]+$/ :Test "hi"
  DoBlah x, y
}
