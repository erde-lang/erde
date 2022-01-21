local C = require('erde.constants')
local rules = require('erde.rules')
local tokenize = require('erde.tokenize')

-- -----------------------------------------------------------------------------
-- Tokenizer
-- -----------------------------------------------------------------------------

local Tokenizer = setmetatable({}, {
  __call = function(self, text)
    local tokenizer = {}
    setmetatable(tokenizer, { __index = self })

    if text ~= nil then
      tokenizer:reset(text)
    end

    return tokenizer
  end,
})

-- -----------------------------------------------------------------------------
-- Methods
-- -----------------------------------------------------------------------------

function Tokenizer:reset(text)
  self.buffer = text
  self.bufIndex = 1
  self.bufValue = text:sub(1, 1)
  self.tokens = {}
end

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

-- -----------------------------------------------------------------------------
-- Macros
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

      local interpolationTokenizer = Tokenizer(text)
      for i, token in pairs(interpolationTokenizer:tokenize()) do
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
-- Tokenize
-- -----------------------------------------------------------------------------

function Tokenizer:tokenize()
  self:Space()

  while self.bufValue ~= '' do
    if WORD_HEAD[self.bufValue] then
      local token = self:consume()

      while WORD_BODY[self.bufValue] do
        token = token .. self:consume()
      end

      self:commit(token)
    elseif DIGIT[self.bufValue] then
      local token = self:consume()

      while DIGIT[self.bufValue] do
        token = token .. self:consume()
      end

      self:commit(token)
    elseif self.bufValue == '.' and C.BINOPS[self:peek(3)] then
      -- Tokenize operators of length 3. This exploits the fact that all ops of
      -- length 3 are binops that start with a period.
      self:commit(self:consume(3))
    elseif C.BINOPS[self:peek(2)] then
      -- Tokenize operators of length 2. This exploits the fact
      -- that the only unop of length 2 is also a valid binop.
      self:commit(self:consume(2))
    elseif self.bufValue == '\n' then
      self:commit(self:consume())
      while self.bufValue == '\n' do
        self:consume()
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
-- Return
-- -----------------------------------------------------------------------------

return Tokenizer
