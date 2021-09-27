local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  Arg = {
    pattern = _.Sum({
      _.Cc(false) * _.CsV('Name'),
      _.Cc(true) * _.V('Destructure'),
    }),
    compiler = function(isdestructure, arg)
      if isdestructure then
        local tmpname = _.newtmpname()
        return { name = tmpname, prebody = _.compiledestructure(true, arg, tmpname) }
      else
        return { name = arg, prebody = false }
      end
    end,
  },
  OptArg = {
    pattern = _.V('Arg') * _.Pad('=') * _.V('Expr'),
    compiler = function(arg, expr)
      return {
        name = arg.name,
        prebody = supertable({
          ('if %s == nil then %s = %s end'):format(arg.name, arg.name, expr),
          arg.prebody,
        }):join(' '),
      }
    end,
  },
  VarArgs = {
    pattern = _.Pad('...') * _.V('Name') ^ -1,
    compiler = function(name)
      return {
        name = name,
        prebody = ('local %s = {...}'):format(name),
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

      return {
        names = supertable(
          params:map(function(param) return param.name end),
          varargs and { '...' }
        ):join(','),
        prebody = params
          :filter(function(param) return param.prebody end)
          :map(function(param) return param.prebody end)
          :join(' '),
      }
    end,
  },
  FunctionExprBody = {
    pattern = _.V('Expr'),
    compiler = _.template('return %1'),
  },
  FunctionBody = {
    pattern = _.Pad('{') * _.V('Block') * _.Pad('}') + _.V('FunctionExprBody'),
    compiler = echo,
  },
  ArrowFunction = {
    pattern = _.Sum({
      _.Cc(false) * _.V('Params') * _.Pad('->') * _.V('FunctionBody'),
      _.Cc(true) * _.V('Params') * _.Pad('=>') * _.V('FunctionBody'),
    }),
    compiler = function(needself, params, body)
      local varargs = params[#params]
        and params[#params].varargs
          and params:pop()

      local names = supertable(
        needself and { 'self' },
        params:map(function(param) return param.name end),
        varargs and { '...' }
      ):join(',')

      local prebody = params
        :filter(function(param) return param.prebody end)
        :map(function(param) return param.prebody end)
        :join(' ')

      return ('function(%s) %s %s end'):format(names, prebody, body)
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
    compiler = function(islocal, name, params, block)
      return ('%s %s(%s) %s %s end'):format(
        islocal and 'local function' or 'function',
        name,
        params.names,
        params.prebody,
        block
      )
    end,
  },
}
