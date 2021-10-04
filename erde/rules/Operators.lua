local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function compileOp(lhs, op, rhs, ...)
  if op == nil then
    return lhs
  elseif op == '??' then
    local tmpName = _.newTmpName()
    lhs = ([[(function()
      local %s = %s
      if %s ~= nil then return %s else return %s end
    end)()]]):format(tmpName, lhs, tmpName, tmpName, rhs)
  elseif op == '&' then
    lhs = ('%s and %s'):format(lhs, rhs)
  elseif op == '|' then
    lhs = ('%s or %s'):format(lhs, rhs)
  elseif op == '//' and not _VERSION:find('5.[34]') then
    lhs = ('math.floor(%s / %s)'):format(lhs, rhs)
  elseif op == '-' then
    -- Need the space, otherwise expressions like `1 - -1` will produce
    -- comments!
    lhs = lhs..op..' '..rhs
  elseif op:sub(1, 1) == '.' and op ~= '..' then
    if _VERSION:find('5.[34]') then
      lhs = lhs..op:sub(2)..rhs
    elseif op == '.|' then
      lhs = ('require("bit").bor(%s,%s)'):format(lhs, rhs)
    elseif op == '.&' then
      lhs = ('require("bit").band(%s,%s)'):format(lhs, rhs)
    elseif op == '.~' then
      lhs = ('require("bit").bxor(%s,%s)'):format(lhs, rhs)
    elseif op == '.>>' then
      lhs = ('require("bit").rshift(%s,%s)'):format(lhs, rhs)
    elseif op == '.<<' then
      lhs = ('require("bit").lshift(%s,%s)'):format(lhs, rhs)
    end
  else
    lhs = lhs..op..rhs
  end

  local rest = supertable({ ... })
  if #rest > 0 then
    op, rhs = rest:remove(1, 2)
    return compileOp(lhs, op, rhs, rest:unpack())
  else
    return lhs
  end
end

-- -----------------------------------------------------------------------------
-- Operators
-- -----------------------------------------------------------------------------

local Operators = {
  AssignOp = {
    pattern = _.Product({
      _.V('Id'),
      _.Pad(_.Product({
        _.C(_.Sum({
          '??', '|', '&', '==', '~=', '<=', '>=', '<', '>', '.|', '.~', '.&',
          '.<<', '.>>', '..', '+', '-', '*', '//', '/', '%', '^',
        })),
        _.P('=')
      })),
      _.CsV('Expr'),
    }),
    compiler = _.indexChain(function(id, op, expr)
      return id..'='..compileOp(id, op, expr)
    end),
  },
}

-- -----------------------------------------------------------------------------
-- Complex Operators
--
-- These are operators that are either nonbinary or require a custom compiler.
-- -----------------------------------------------------------------------------

local function UnaryOp(Operand)
  return {
    pattern = _.Pad(_.C(_.Sum({ '.~', '~', '-', '#' }))) * Operand,
    compiler = function(op, expr)
      if op == '.~' then
        return _VERSION:find('5.[34]')
          and '~'..expr
          or 'require("bit").bnot('..expr..')'
      elseif op == '~' then
        return 'not '..expr
      else
        return op..expr
      end
    end,
  }
end

local function TernaryOp(Operand)
  return {
    pattern = Operand * _.Pad('?') * Operand * _.Pad(':') * Operand,
    compiler = function(op1, op2, op3)
      return ('(function() if %s then return %s else return %s end end)()')
        :format(op1, op2, op3)
    end,
  }
end

local function PipeOp(Operand)
  return {
    pattern = Operand * (
      _.Product({
        _.Pad('>>'),
        _.Sum({
          _.Cc(1) * _.V('Id'),
          _.Cc(2) * _.CsV('Expr'),
        }),
        _.Product({
          -_.Pad(')'),
          _.Pad('?') * _.Cc(true) + _.Cc(false),
        }),
      }) / _.pack
    ) ^ 1,
    compiler = function(pipee, ...)
      local idCompiler = _.indexChain(
        function(id) return id end,
        function(id) return 'return '..id end
      )

      return supertable({ ... }):reduce(function(pipeOp, capture)
        local variant, pipe, opt = capture[1], capture[2], capture[3]

        if variant == 1 then
          local lastChain = pipe.chain[#pipe.chain]

          if lastChain and lastChain.variant == 3 then
            lastChain.value:insert(1, pipeOp)
          else
            pipe.chain:push({
              opt = opt,
              variant = 3,
              value = supertable({ pipeOp }),
            })
          end

          return idCompiler(pipe)
        else
          return idCompiler({
              base = pipe,
              chain = {
                opt = opt,
                variant = 3,
                value = supertable({ pipeOp }),
              },
            })
        end
      end, pipee)
    end,
  }
end

-- -----------------------------------------------------------------------------
-- Precedence Levels
-- -----------------------------------------------------------------------------

local Precedence = {
  PipeOp,
  TernaryOp,
  { '??' },
  { '|' },
  { '&' },
  { '==', '~=', '<=', '>=', '<', '>' },
  { '.|' },
  { '.~' },
  { '.&' },
  { '.<<', '.>>' },
  { '..' },
  { '+', '-' },
  { '*', '//', '/', '%' },
  UnaryOp,
  { '^' },
}

for i, ops in ipairs(Precedence) do
  local Operand = i < #Precedence
    and _.CsV('Op'..tostring(i + 1)) + _.CsV('SubExpr')
    or _.CsV('SubExpr')

  -- For complex operators, we provide a function that returns the
  -- { pattern, compiler } table. Here we only check whether we have a function
  -- to generate the grammar but this is quite crude, as it will fail if there
  -- are multiple complex operators that require the same precedence level.
  -- However, as of October 4, 2021, this perfectly suffices and greatly reduces
  -- the code complexity. If a new complex operator is added, it is worth great
  -- consideration to simply give it its own precedence level.
  if type(ops) == 'function' then
    local op = ops(Operand)
    -- Make sure we match 'Operand' so we can recurse the precedence levels!
    Operators['Op'..i] = {
      pattern = _.Sum({
        _.Cc(true) * op.pattern,
        _.Cc(false) * Operand,
      }),
      compiler = function(isComplex, ...)
        if isComplex and type(op.compiler) == 'function' then
          return op.compiler(...)
        else
          return ...
        end
      end,
    }
  else
    Operators['Op'..i] = {
      pattern = _.Sum({
        Operand - _.Pad(_.C(_.Sum(ops))),
        Operand * (_.Pad(_.C(_.Sum(ops))) * Operand) ^ 1,
      }),
      compiler = compileOp,
    }
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Operators
