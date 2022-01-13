local C = require('erde.constants')
local rules = require('erde.rules')

-- Foward declare for recursive use in Tokenizer
local tokenize

local Tokenizer = {}
local TokenizerMT = { __index = Tokenizer }

-- -----------------------------------------------------------------------------
-- Tokenizer Methods
-- -----------------------------------------------------------------------------

function Tokenizer:commit(token)
  self.tokens[#self.tokens + 1] = token
end

function Tokenizer:peek(n)
  return self.buffer:sub(self.bufIndex, self.bufIndex + n - 1)
end

function Tokenizer:consume(n)
  n = n or 1
  local consumed = n == 1 and self.bufValue or self:peek(n)
  self.bufIndex = self.bufIndex + n
  self.bufValue = self.buffer:sub(self.bufIndex, self.bufIndex)
  return consumed
end

function Tokenizer:tokenize()
  self:Space()

  while self.bufValue ~= '' do
    if C.WORD_HEAD[self.bufValue] then
      local token = self:consume()

      while C.WORD_BODY[self.bufValue] do
        token = token .. self:consume()
      end

      self:commit(token)
    elseif C.DIGIT[self.bufValue] then
      local token = self:consume()

      while C.DIGIT[self.bufValue] do
        token = token .. self:consume()
      end

      self:commit(token)
    elseif C.SYMBOLS[self:peek(3)] then
      self:commit(self:consume(3))
    elseif C.SYMBOLS[self:peek(2)] then
      self:commit(self:consume(2))
    elseif self.bufValue == '\n' then
      self:consume()
      self:Space()

      if self.bufValue == '\n' then
        -- Record 2 or more newlines for formatting
        self.newlines[self.bufIndex] = true
        while self.bufValue == '\n' do
          self:consume()
        end
      end
    elseif self.bufValue == '"' or self.bufValue == "'" then
      self:String({ long = false, interpolation = true })
    elseif self:peek(2):match('^%[[[=]$') then
      self:String({ long = true, interpolation = true })
    elseif self:peek(2):match('^--$') then
      self:commit(self:consume(2))

      if self:peek(2):match('^%[[[=]$') then
        self:String({ long = true, interpolation = false })
      else
        local token = ''

        while self.bufValue ~= '' and self.bufValue ~= '\n' do
          token = token .. self:consume()
        end

        self:commit(token)
      end
    else
      self:commit(self:consume())
    end

    self:Space()
  end

  return self.tokens
end

-- -----------------------------------------------------------------------------
-- Tokenizer Macros
-- -----------------------------------------------------------------------------

function Tokenizer:Space()
  while self.bufValue == ' ' or self.bufValue == '\t' do
    self:consume()
  end
end

function Tokenizer:String(opts)
  local strClose
  if not opts.long then
    strClose = self:consume()
    self:commit(strClose) -- commit opening
  else
    self:consume() -- '['

    local strEq = ''
    while self.bufValue == '=' do
      strEq = strEq .. self:consume()
    end

    if self:consume() ~= '[' then
      -- TODO: invalid
      error()
    end

    strClose = ']' .. strEq .. ']'
    self:commit('[' .. strEq .. '[') -- commit opening
  end

  local token = ''
  local isEscaped = false

  while self:peek(#strClose) ~= strClose do
    if self.bufValue == '' or not opts.long and self.bufValue == '\n' then
      -- TODO: unterminated
      error()
    elseif isEscaped then
      isEscaped = false
      token = token .. self:consume()
    elseif opts.interpolation and self.bufValue == '{' then
      if #token > 0 then
        self:commit(token)
        token = ''
      end

      self:commit(self:consume()) -- '{'

      -- Keep track of brace depth to differentiate end of interpolation from
      -- nested braces
      local braceDepth = 0
      local text = ''

      while braceDepth > 0 or self.bufValue ~= '}' do
        if self.bufValue == '{' then
          braceDepth = braceDepth + 1
        elseif self.bufValue == '}' then
          braceDepth = braceDepth - 1
        end

        text = text .. self:consume()
      end

      for i, token in pairs(tokenize(text)) do
        self:commit(token)
      end

      self:commit(self:consume()) -- '}'
    else
      isEscaped = self.bufValue == '\\'
      token = token .. self:consume()
    end
  end

  if #token > 0 then
    self:commit(token)
  end

  self:commit(self:consume(#strClose))
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

-- Declaration at top of module
tokenize = function(text)
  return setmetatable({
    buffer = text,
    bufIndex = 1,
    bufValue = text:sub(1, 1),
    tokens = {},
    newlines = {},
  }, TokenizerMT):tokenize()
end

return tokenize
