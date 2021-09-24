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
    pattern = _.Pad('(') * _.V('ReturnList') * _.Pad(')') + _.List(_.V('Expr')),
    compiler = _.concat(','),
  },
  Return = {
    pattern = _.PadC('return') * _.V('ReturnList') ^ -1,
    compiler = _.concat(' '),
  },
  FunctionCall = {
    pattern = _.Product({
      _.V('Id'),
      _.Pad(':') * _.CsV('Name') + _.Cc(false),
      _.Pad('?') * _.Cc(true) + _.Cc(false),
      _.Pad('('),
      _.List(_.CsV('Expr')) + _.V('Space'),
      _.Pad(')'),
    }),
    compiler = function(base, indexchain, method, optcall, exprlist)
      if optcall then
        return _.indexchain(
          _.template('if %1 ~= nil then %1(%2) end'),
          _.template('if %1 ~= nil then return %1(%2) end')
        )(base, indexchain, exprlist:join(','))
      else
        return _.indexchain(
          _.template('%1(%2)'),
          _.template('return %1(%2)')
        )(base, indexchain, exprlist:join(','))
      end

      return ('%s(%s)'):format(
        method and id..':'..method or id,
        exprlist:join(',')
      )
    end,
  },
}
