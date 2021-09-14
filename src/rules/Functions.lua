require('env')()

return {
  Arg = {
    parser = Sum({
      Cc(false) * V('Name'),
      Cc(true) * V('Destructure'),
    }),
    oldcompiler = function(isdestructure, arg)
      if isdestructure then
        local tmpname = newtmpname()
        return { name = tmpname, prebody = compiledestructure(true, arg, tmpname) }
      else
        return { name = arg, prebody = false }
      end
    end,
  },
  OptArg = {
    parser = V('Arg') * Pad('=') * V('Expr'),
    oldcompiler = function(arg, expr)
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
    parser = Pad('...') * V('Name') ^ -1,
    oldcompiler = function(name)
      return {
        name = name,
        prebody = ('local %s = {...}'):format(name),
        varargs = true,
      }
    end,
  },
  ParamComma = {
    parser = (#Pad(')') * Pad(',') ^ -1) + Pad(','),
  },
  Params = {
    parser = V('Arg') + Product({
      Pad('('),
      (V('Arg') * V('ParamComma')) ^ 0,
      (V('OptArg') * V('ParamComma')) ^ 0,
      (V('VarArgs') * V('ParamComma')) ^ -1,
      Cc({}),
      Pad(')'),
    }),
    oldcompiler = pack,
  },
  FunctionExprBody = {
    parser = V('Expr'),
    oldcompiler = template('return %1'),
  },
  FunctionBody = {
    parser = Pad('{') * V('Block') * Pad('}') + V('FunctionExprBody'),
    oldcompiler = echo,
  },
  Function = {
    parser = Sum({
      Cc(false) * V('Params') * Pad('->') * V('FunctionBody'),
      Cc(true) * V('Params') * Pad('=>') * V('FunctionBody'),
    }),
    oldcompiler = function(needself, params, body)
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
    parser = Pad('(') * V('ReturnList') * Pad(')') + Csv(V('Expr')),
    oldcompiler = concat(','),
  },
  Return = {
    parser = PadC('return') * V('ReturnList') ^ -1,
    oldcompiler = concat(' '),
  },
  FunctionCall = {
    parser = Product({
      V('Id'),
      (PadC(':') * V('Name')) ^ -1,
      PadC('('),
      Csv(V('Expr'), true) + V('Space'),
      PadC(')'),
    }),
    oldcompiler = concat(),
  },
}
