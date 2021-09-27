local state = {
  currentLine = 1,
  currentLineStart = 1,
  tmpNameCounter = 0,
}

function state:reset()
  self.currentLine = 1
  self.currentLineStart = 1
end

return state
