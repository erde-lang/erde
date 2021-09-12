require('erde.env')()

return {
  Arg = {
    pattern = Sum({
      Cc(false) * V('Name'),
      Cc(true) * V('Destructure'),
    }),
    compiler = function(isdestructure, arg)
      if isdestructure then
        local tmpname = newtmpname()
        return { name = tmpname, prebody = compiledestructure(true, arg, tmpname) }
      else
        return { name = arg, prebody = false }
      end
    end,
  },
  OptArg = {
    pattern = V('Arg') * Pad('=') * V('Expr'),
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
    pattern = Pad('...') * V('Name') ^ -1,
    compiler = function(name)
      return {
        name = name,
        prebody = ('local %s = {...}'):format(name),
        varargs = true,
      }
    end,
  },
  ParamComma = {
    pattern = (#Pad(')') * Pad(',') ^ -1) + Pad(','),
  },
  Params = {
    pattern = V('Arg') + Product({
      Pad('('),
      (V('Arg') * V('ParamComma')) ^ 0,
      (V('OptArg') * V('ParamComma')) ^ 0,
      (V('VarArgs') * V('ParamComma')) ^ -1,
      Cc({}),
      Pad(')'),
    }),
    compiler = pack,
  },
  FunctionExprBody = {
    pattern = V('Expr'),
    compiler = template('return %1'),
  },
  FunctionBody = {
    pattern = Pad('{') * V('Block') * Pad('}') + V('FunctionExprBody'),
    compiler = echo,
  },
  Function = {
    pattern = Sum({
      Cc(false) * V('Params') * Pad('->') * V('FunctionBody'),
      Cc(true) * V('Params') * Pad('=>') * V('FunctionBody'),
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
    pattern = Pad('(') * V('ReturnList') * Pad(')') + Csv(V('Expr')),
    compiler = concat(','),
  },
  Return = {
    pattern = PadC('return') * V('ReturnList') ^ -1,
    compiler = concat(' '),
  },
  FunctionCall = {
    pattern = Product({
      V('Id'),
      (PadC(':') * V('Name')) ^ -1,
      PadC('('),
      Csv(V('Expr'), true) + V('Space'),
      PadC(')'),
    }),
    compiler = concat(),
  },
}
