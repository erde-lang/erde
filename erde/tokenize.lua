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
  local tokenId = #self.tokens + 1
  self.tokens[tokenId] = token
  self.tokenInfo[tokenId] = {
    line = self.line,
    column = self.column,
  }

  self.column = self.column + #token
end

function Tokenizer:peek(n)
  return self.text:sub(self.charIndex, self.charIndex + n - 1)
end

function Tokenizer:consume(n)
  n = n or 1
  local consumed = n == 1 and self.char or self:peek(n)
  self.charIndex = self.charIndex + n
  self.char = self.text:sub(self.charIndex, self.charIndex)
  return consumed
end

function Tokenizer:tokenize()
  self:Space()

  while self.char ~= '' do
    if C.WORD_HEAD[self.char] then
      local token = self:consume()

      while C.WORD_BODY[self.char] do
        token = token .. self:consume()
      end

      self:commit(token)
    elseif C.DIGIT[self.char] then
      if self:peek(2):match('0[xX]') then
        self:Number({ hex = true })
      else
        self:Number()
      end
    elseif self:peek(2):match('%.[0-9]') then
      self:Number()
    elseif C.SYMBOLS[self:peek(3)] then
      self:commit(self:consume(3))
    elseif C.SYMBOLS[self:peek(2)] then
      self:commit(self:consume(2))
    elseif self.char == '\n' then
      self:Newline()
      self:Space()

      if self.char == '\n' then
        -- Record 2 or more newlines for formatting
        self.newlines[#self.tokens] = true
      end

      while self.char == '\n' do
        self:Newline()
        self:Space()
      end
    elseif self.char == '"' or self.char == "'" then
      local tokens = self:String({ long = false, interpolation = true })
      for i, token in pairs(tokens) do
        self:commit(token)
      end
    elseif self:peek(2):match('%[[[=]') then
      local tokens = self:String({ long = true, interpolation = true })
      for i, token in pairs(tokens) do
        self:commit(token)
      end
    elseif self:peek(2):match('%-%-') then
      local comment = { line = self.line, column = self.column }
      self:consume(2)

      if self:peek(2):match('%[[[=]') then
        comment.token = self:String({ long = true, interpolation = false })[1]
      else
        local token = ''

        while self.char ~= '' and self.char ~= '\n' do
          token = token .. self:consume()
        end

        comment.token = token
      end

      self.comments[#self.comments + 1] = comment
    else
      self:commit(self:consume())
    end

    self:Space()
  end
end

-- -----------------------------------------------------------------------------
-- Tokenizer Macros
-- -----------------------------------------------------------------------------

function Tokenizer:Newline()
  self.column = 1
  self.line = self.line + 1
  return self:consume()
end

function Tokenizer:Space()
  while self.char == ' ' or self.char == '\t' do
    self:consume()
    self.column = self.column + 1
  end
end

function Tokenizer:Number(opts)
  opts = opts or {}
  local token, lookup, exponent

  if opts.hex then
    lookup = C.HEX
    exponent = '[pP]'

    token = self:consume(2) -- 0[xX]
    if not C.HEX[self.char] and self.char ~= '.' then
      error('empty hex')
    end
  else
    token = ''
    lookup = C.DIGIT
    exponent = '[eE]'
  end

  while lookup[self.char] do
    token = token .. self:consume()
  end

  if self.char == '.' then
    token = token .. self:consume()

    if not lookup[self.char] then
      error('empty decimal') -- invalid
    end

    while lookup[self.char] do
      token = token .. self:consume()
    end
  end

  if self.char:match(exponent) then
    token = token .. self:consume()

    if self.char == '+' or self.char == '-' then
      token = token .. self:consume()
    end

    if not C.DIGIT[self.char] then
      error('empty exponent')
    end

    while C.DIGIT[self.char] do
      token = token .. self:consume()
    end
  end

  if C.ALPHA[self.char] then
    error('word cannot start with digit')
  end

  self:commit(token)
end

function Tokenizer:String(opts)
  local tokens = {}

  local strClose
  if not opts.long then
    tokens[#tokens + 1] = self.char
    strClose = self:consume()
  else
    self:consume() -- '['

    local strEq = ''
    while self.char == '=' do
      strEq = strEq .. self:consume()
    end

    if self:consume() ~= '[' then
      -- TODO: invalid
      error('invalid long str')
    end

    tokens[#tokens + 1] = '[' .. strEq .. '['
    strClose = ']' .. strEq .. ']'
  end

  local token = ''

  while self:peek(#strClose) ~= strClose do
    if self.char == '' then
      -- TODO: unterminated
      error('unterminated string')
    elseif self.char == '\n' then
      if not opts.long then
        error('unterminated string')
      else
        token = token .. self:Newline()
      end
    elseif self.char == '\\' then
      self:consume()
      if self.char == '{' or self.char == '}' then
        token = token .. self:consume()
      else
        token = token .. '\\' .. self:consume()
      end
    elseif opts.interpolation and self.char == '{' then
      if #token > 0 then
        tokens[#tokens + 1] = token
        token = ''
      end

      tokens[#tokens + 1] = self:consume() -- '{'

      -- Keep track of brace depth to differentiate end of interpolation from
      -- nested braces
      local braceDepth = 0
      local text = ''

      while braceDepth > 0 or self.char ~= '}' do
        if self.char == '{' then
          braceDepth = braceDepth + 1
        elseif self.char == '}' then
          braceDepth = braceDepth - 1
        elseif self.char == '' then
          -- TODO: unterminated
          error('unterminated interpolation')
        end

        text = text .. self:consume()
      end

      -- TODO: parsing error on nested tokenize
      for i, token in pairs(tokenize(text)) do
        tokens[#tokens + 1] = token
      end

      tokens[#tokens + 1] = self:consume() -- '}'
    else
      token = token .. self:consume()
    end
  end

  if #token > 0 then
    tokens[#tokens + 1] = token -- '}'
  end

  tokens[#tokens + 1] = self:consume(#strClose)
  return tokens
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

-- Declaration at top of module
tokenize = function(text)
  local tokenizer = setmetatable({
    text = text,
    char = text:sub(1, 1),
    charIndex = 1,
    line = 1,
    column = 1,
    tokens = {},
    tokenInfo = {},
    newlines = {},
    comments = {},
  }, TokenizerMT)

  local ok, errorMsg = pcall(function()
    tokenizer:tokenize()
  end)

  if not ok then
    error(
      ('Error (Line %d, Column %d): %s'):format(
        tokenizer.line,
        tokenizer.column,
        errorMsg
      )
    )
  end

  return tokenizer.tokens
end

return tokenize
