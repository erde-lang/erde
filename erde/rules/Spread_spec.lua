-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Spread.parse', function()
  spec('ruleName', function()
    assert.are.equal('Spread', parse.Spread('...x').ruleName)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Spread.compile', function()
  print(compile.Block([[
    local a = { 3, 4, 5 }
    local function sum(t) {
      local answer = 0
      for i, value in ipairs(t) {
        answer += value
      }
      return answer
    }
    return sum({ 1, 2, ...a, 6 })
  ]]))
  spec('table spread', function()
    assert.run(
      6,
      compile.Block([[
        local a = { 3, 4, 5 }
        local function sum(t) {
          local answer = 0
          for i, value in ipairs(t) {
            answer += value
          }
          return answer
        }
        return sum({ 1, 2, ...a, 6 })
      ]])
    )
  end)
end)
