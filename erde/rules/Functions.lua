local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  Arg = {
    pattern = _.Sum({
      _.Cc(false) * _.CsV('Name'),
      _.Cc(true) * _.V('Destructure'),
    }),
    compiler = function(isDestructure, arg)
      if isDestructure then
        local tmpName = _.newTmpName()
        return {
          name = tmpName,
          prebody = _.compileDestructure(true, arg, tmpName),
        }
      else
        return { name = arg, prebody = '' }
      end
    end,
  },
  OptArg = {
    pattern = _.V('Arg') * _.Pad('=') * _.V('Expr'),
    compiler = function(arg, expr)
      return {
        name = arg.name,
        prebody = ('if %s == nil then %s = %s end %s'):format(
          arg.name,
          arg.name,
          expr,
          arg.prebody
        ),
      }
    end,
  },
  VarArgs = {
    pattern = _.Pad('...') * _.V('Name') ^ -1,
    compiler = function(name)
      return {
        name = name,
        prebody = 'local '..name..' = {...}',
        varargs = true,
      }
    end,
  },
  Params = {
    pattern = function()
      local ParamComma = (#_.Pad(')') * _.Pad(',') ^ -1) + _.Pad(',')
      return _.Sum({
        _.V('Arg'),
        _.Product({
          _.Pad('('),
          (_.V('Arg') * ParamComma) ^ 0,
          (_.V('OptArg') * ParamComma) ^ 0,
          (_.V('VarArgs') * ParamComma) ^ -1,
          _.Pad(')'),
        }),
      }) / _.pack
    end,
    compiler = function(params)
      local varargs = params[#params]
        and params[#params].varargs
          and params:pop()
      
      local names = params:map(function(param)
        return param.name
      end) 

      return {
        names = varargs and names:push('...') or names,
        prebody = params
          :filter(function(param) return param.prebody end)
          :map(function(param) return param.prebody end)
          :join(' '),
      }
    end,
  },
  ArrowFunction = {
    pattern = _.Product({
      _.V('Params'),
      _.Sum({
        _.Cc(false) * _.Pad('->'),
        _.Cc(true) * _.Pad('=>'),
      }),
      _.Sum({
        _.Cc(false) * _.V('BraceBlock'),
        _.Cc(true) * _.CsV('Expr'),
      }),
    }),
    compiler = function(params, isFat, isExprBody, body)
      if isFat then
        params.names:insert(1, 'self')
      end

      return ('function(%s) %s %s end'):format(
        params.names:join(','),
        params.prebody,
        (isExprBody and 'return ' or '') .. body
      )
    end,
  },
  FunctionDeclaration = {
    pattern = _.Product({
      _.Pad('local') * _.Cc(true) + _.Cc(false),
      _.Pad('function'),
      _.CsV('Name'),
      _.V('Params'),
      _.V('BraceBlock'),
    }),
    compiler = function(isLocal, name, params, body)
      return ('%s function %s(%s) %s %s end'):format(
        isLocal and 'local' or '',
        name,
        params.names:join(','),
        params.prebody,
        body
      )
    end,
  },
}
