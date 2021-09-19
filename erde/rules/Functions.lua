local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  Arg = {
    pattern = _.Sum({
      _.Cc(false) * _.V('Name'),
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
  ParamComma = {
    pattern = (#_.Pad(')') * _.Pad(',') ^ -1) + _.Pad(','),
  },
  Params = {
    pattern = _.V('Arg') + _.Product({
      _.Pad('('),
      (_.V('Arg') * _.V('ParamComma')) ^ 0,
      (_.V('OptArg') * _.V('ParamComma')) ^ 0,
      (_.V('VarArgs') * _.V('ParamComma')) ^ -1,
      _.Cc({}),
      _.Pad(')'),
    }),
    compiler = _.pack,
  },
  FunctionExprBody = {
    pattern = _.V('Expr'),
    compiler = _.template('return %1'),
  },
  FunctionBody = {
    pattern = _.Pad('{') * _.V('Block') * _.Pad('}') + _.V('FunctionExprBody'),
    compiler = echo,
  },
  Function = {
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
  ReturnList = {
    pattern = _.Pad('(') * _.V('ReturnList') * _.Pad(')') + _.Csv(_.V('Expr')),
    compiler = _.concat(','),
  },
  Return = {
    pattern = _.PadC('return') * _.V('ReturnList') ^ -1,
    compiler = _.concat(' '),
  },
  FunctionCall = {
    pattern = _.Product({
      _.V('Id'),
      (_.PadC(':') * _.V('Name')) ^ -1,
      _.PadC('('),
      _.Csv(_.V('Expr'), true) + _.V('Space'),
      _.PadC(')'),
    }),
    compiler = _.concat(),
  },
}
