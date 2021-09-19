local state = {
  currentline = 1,
  currentlinestart = 1,
  tmpnamecounter = 0,
}

function state:reset()
  self.currentline = 1
  self.currentlinestart = 1
end

return state
