return {
  text = nil,
  char = nil,
  char_index = nil,
  current_line = nil,

  tokens = nil,
  token_lines = nil,
  num_tokens = nil,

  source_name = nil,

  reset = function(self, text, source_name)
    self.text = text
    self.char = text:sub(1, 1)
    self.char_index = 1
    self.current_line = 1

    self.tokens = {}
    self.num_tokens = 0
    self.token_lines = {}

    if source_name then
      self.source_name = source_name
    elseif #text < 7 then
      self.source_name = '[string "' .. text .. '"]'
    else
      self.source_name = '[string "' .. text:sub(1, 6) .. '..."]'
    end
  end,
}
