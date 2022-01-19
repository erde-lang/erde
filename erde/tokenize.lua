local C = require('erde.constants')

-- forward declare for use in TokenizeContext:Interpolation
local tokenize

-- -----------------------------------------------------------------------------
-- Lookup Tables
-- -----------------------------------------------------------------------------

local WORD_HEAD = { ['_'] = true }
local WORD_BODY = { ['_'] = true }
local DIGIT = {}

for byte = string.byte('a'), string.byte('z') do
  local char = string.char(byte)
  WORD_HEAD[char] = true
  WORD_BODY[char] = true
end

for byte = string.byte('A'), string.byte('Z') do
  local char = string.char(byte)
  WORD_HEAD[char] = true
  WORD_BODY[char] = true
end

for byte = string.byte('0'), string.byte('9') do
  local char = string.char(byte)
  WORD_BODY[char] = true
  DIGIT[char] = true
end

-- -----------------------------------------------------------------------------
-- TokenizeContext
-- -----------------------------------------------------------------------------

local TokenizeContext = setmetatable({}, {
  __call = function(self, text)
    local ctx = {
      buffer = text,
      bufIndex = 1,
      bufValue = text:sub(1, 1),
      tokens = {},
    }

    setmetatable(ctx, { __index = self })
    return ctx
  end,
})

function TokenizeContext:commit(token)
  self.tokens[#self.tokens + 1] = token
end

function TokenizeContext:peek(n)
  return self.buffer:sub(self.bufIndex, self.bufIndex + n - 1)
end

function TokenizeContext:consume(n)
  n = n or 1
  local consumed = n == 1 and self.bufValue or self:peek(n)
  self.bufIndex = self.bufIndex + n
  self.bufValue = self.buffer:sub(self.bufIndex, self.bufIndex)
  return consumed
end

function TokenizeContext:Space()
  while self.bufValue == ' ' or self.bufValue == '\t' do
    self:consume()
  end
end

function TokenizeContext:String(opts)
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
-- Tokenize
-- -----------------------------------------------------------------------------

function tokenize(text)
  local ctx = TokenizeContext(text)

  ctx:Space()

  while ctx.bufValue ~= '' do
    if WORD_HEAD[ctx.bufValue] then
      local token = ctx:consume()

      while WORD_BODY[ctx.bufValue] do
        token = token .. ctx:consume()
      end

      ctx:commit(token)
    elseif DIGIT[ctx.bufValue] then
      local token = ctx:consume()

      while DIGIT[ctx.bufValue] do
        token = token .. ctx:consume()
      end

      ctx:commit(token)
    elseif ctx.bufValue == '.' and C.BINOPS[ctx:peek(3)] then
      -- Tokenize operators of length 3. This exploits the fact that all ops of
      -- length 3 are binops that start with a period.
      ctx:commit(ctx:consume(3))
    elseif C.BINOPS[ctx:peek(2)] then
      -- Tokenize operators of length 2. This exploits the fact
      -- that the only unop of length 2 is also a valid binop.
      ctx:commit(ctx:consume(2))
    elseif ctx.bufValue == '\n' then
      ctx:commit(ctx:consume())
      while ctx.bufValue == '\n' do
        ctx:consume()
      end
    elseif ctx.bufValue == '"' or ctx.bufValue == "'" then
      ctx:String({ long = false, interpolation = true })
    elseif ctx:peek(2):match('^%[[[=]$') then
      ctx:String({ long = true, interpolation = true })
    elseif ctx:peek(2):match('^--$') then
      ctx:commit(ctx:consume(2))

      if ctx:peek(2):match('^%[[[=]$') then
        ctx:String({ long = true, interpolation = false })
      else
        local token = ''

        while ctx.bufValue ~= '' and ctx.bufValue ~= '\n' do
          token = token .. ctx:consume()
        end

        ctx:commit(token)
      end
    else
      ctx:commit(ctx:consume())
    end

    ctx:Space()
  end

  return ctx.tokens
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return tokenize
