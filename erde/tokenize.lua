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

      if #text:gsub('[ \t\n]', '') == 0 then
        error('empty interpolation')
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
-- Optimized Tokenizer
-- -----------------------------------------------------------------------------

function optimalTokenize(text)
  local char, charIndex = text:sub(1, 1), 1
  local line, column = 1, 1
  local tokens, tokenLen = {}, 0
  local tokenInfo = {}
  local newlines = {}
  local comments = {}

  local state, token = 1, ''
  local numLookup, numExp1, numExp2
  local strClose, strCloseLen, strEq
  local isLong, isComment
  local braceDepth

  local function commit(token)
    tokenLen = tokenLen + 1
    tokens[tokenLen] = token
    tokenInfo[tokenLen] = { line = line, column = column }
    column = column + #token
  end

  local function peek(n)
    return text:sub(charIndex, charIndex + n - 1)
  end

  local function consume(n)
    n = n or 1
    local consumed = n == 1 and char or peek(n)
    charIndex = charIndex + n
    char = text:sub(charIndex, charIndex)
    return consumed
  end

  local function Newline()
    column = 1
    line = line + 1
    return consume()
  end

  local function Space()
    while char == ' ' or char == '\t' do
      consume()
      column = column + 1
    end
  end

  ::Iteration::
  Space()
  local peekTwo = peek(2)

  if C.WORD_HEAD[char] then
    token = consume()

    while C.WORD_BODY[char] do
      token = token .. consume()
    end

    commit(token)
  elseif C.DIGIT[char] then
    if peekTwo:match('0[xX]') then
      goto Hex
    else
      goto Decimal
    end
  elseif peekTwo:match('%.[0-9]') then
    goto Decimal
  elseif C.SYMBOLS[peek(3)] then
    commit(consume(3))
  elseif C.SYMBOLS[peekTwo] then
    commit(consume(2))
  elseif char == '\n' then
    Newline()
    Space()

    if char == '\n' then
      -- Record 2 or more newlines for formatting
      newlines[#tokens] = true
    end

    while char == '\n' do
      Newline()
      Space()
    end
  elseif char == '"' or char == "'" then
    goto ShortString
  elseif peekTwo:match('%[[[=]') then
    goto LongString
  elseif peekTwo:match('%-%-') then
    -- TODO
    -- local comment = { line = line, column = column }
    -- consume(2)

    -- if peekTwo:match('%[[[=]') then
    --   goto LongComment
    --   comment.token = String({ long = true, interpolation = false })[1]
    -- else
    --   token = ''

    --   while char ~= '' and char ~= '\n' do
    --     token = token .. consume()
    --   end

    --   comment.token = token
    -- end

    -- comments[#comments + 1] = comment
  else
    commit(consume())
  end

  ::IterationEnd::
  if state == -1 then
    goto InterpolationLoop
  else
    goto Main
  end

  ::Main::
  while char ~= '' do
    goto Iteration
  end

  goto Return

  ::Hex::
  numLookup = C.HEX
  numExp1, numExp2 = 'p', 'P'

  token = consume(2) -- 0[xX]
  if not C.HEX[char] and char ~= '.' then
    error('empty hex')
  end

  goto Number

  ::Decimal::
  token = ''
  numLookup = C.DIGIT
  numExp1, numExp2 = 'e', 'E'
  goto Number

  ::Number::
  while numLookup[char] do
    token = token .. consume()
  end

  if char == '.' then
    token = token .. consume()

    if not numLookup[char] then
      error('empty decimal') -- invalid
    end

    while numLookup[char] do
      token = token .. consume()
    end
  end

  if char == numExp1 or char == numExp2 then
    token = token .. consume()

    if char == '+' or char == '-' then
      token = token .. consume()
    end

    if not C.DIGIT[char] then
      error('empty exponent')
    end

    while C.DIGIT[char] do
      token = token .. consume()
    end
  end

  if C.ALPHA[char] then
    error('word cannot start with digit')
  end

  commit(token)
  goto IterationEnd

  ::LongComment::
  isLong, isComment = true, true
  goto LongString

  ::ShortString::
  isLong, isComment = false, false
  strClose = consume()
  strCloseLen = 1
  commit(strClose) -- strOpen === strClose
  goto String

  ::LongString::
  isLong, isComment = true, false
  consume() -- '['

  strEq = ''
  strCloseLen = 2
  while char == '=' do
    strEq = strEq .. consume()
    strCloseLen = strCloseLen + 1
  end

  if consume() ~= '[' then
    -- TODO: invalid
    error('invalid long str')
  end

  commit('[' .. strEq .. '[')
  strClose = ']' .. strEq .. ']'
  goto String

  ::String::
  while peek(strCloseLen) ~= strClose do
    if char == '' then
      -- TODO: unterminated
      error('unterminated string')
    elseif char == '\n' then
      -- TODO
      if not opts.long then
        error('unterminated string')
      else
        token = token .. Newline()
      end
    elseif char == '\\' then
      consume()
      if char == '{' or char == '}' then
        -- Remove escape for '{', '}' (not allowed in pure lua)
        token = token .. consume()
      else
        token = token .. '\\' .. consume()
      end
    elseif not isComment and char == '{' then
      if #token > 0 then
        commit(token)
        token = ''
      end

      goto Interpolation
    else
      token = token .. consume()
    end
  end

  if #token > 0 then
    commit(token)
  end

  commit(consume(strCloseLen))
  goto IterationEnd

  ::Interpolation::
  state = -1
  commit(consume()) -- '{'

  -- Keep track of brace depth to differentiate end of interpolation from
  -- nested braces
  braceDepth = 0

  ::InterpolationLoop::
  while char ~= '}' or braceDepth > 0 do
    if char == '{' then
      braceDepth = braceDepth + 1
      commit(consume())
    elseif char == '}' then
      braceDepth = braceDepth - 1
      commit(consume())
    elseif char == '' then
      -- TODO: unterminated
      error('unterminated interpolation')
    else
      goto Iteration
    end
  end

  commit(consume()) -- '}'

  state = 1
  goto String

  ::Return::
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
