local C = require('erde.constants')
local utils = require('erde.utils')
local tokenize = require('erde.tokenize')

-- Foward declare
local expression, block, loop_block, function_block

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local tokens, token_lines, num_tokens
local current_token, current_token_index
local current_line, last_line

-- Current block depth during parsing
local block_depth

-- Counter for generating unique names in compiled code.
local tmp_name_counter

-- Break name to use for `continue` statements. This is also used to validate
-- the context of `break` and `continue`.
local break_name

-- Flag to keep track of whether the current block has any `continue` statements.
local has_continue

-- Table for declarations to register `module` scope variables.
local module_names

-- Keeps track of whether the module has a `return` statement. Used to warn the
-- developer if they try to combine `return` with `module` scopes.
local is_module_return_block, has_module_return

-- Keeps track of whether the current block can use varargs as an expression.
-- Required since the Lua _parser_ will throw an error if varargs are used
-- outside a vararg function.
local is_varargs_block

-- Name for the current source being compiled (used in error messages)
local alias

-- Lua target
local lua_target

-- Resolved bit library to use for compiling bit operations. Undefined when
-- compiling to Lua 5.3+ native operators.
local bitlib

-- -----------------------------------------------------------------------------
-- General Helpers
-- -----------------------------------------------------------------------------

local unpack = table.unpack or unpack
local insert = table.insert
local concat = table.concat

local function throw(message, line)
  -- Use error level 0 since we already include alias
  error(('%s:%d: %s'):format(alias, line or current_line or last_line, message), 0)
end

-- -----------------------------------------------------------------------------
-- Parse Helpers
-- -----------------------------------------------------------------------------

local function consume()
  local consumed_token = current_token
  current_token_index = current_token_index + 1
  current_token = tokens[current_token_index]
  current_line = token_lines[current_token_index]
  return consumed_token
end

local function branch(token)
  if token == current_token then
    consume()
    return true
  end
end

local function ensure(is_valid, message)
  if not is_valid then
    throw(message)
  end
end

local function expect(token, prevent_consume)
  ensure(current_token ~= nil, ('unexpected eof (expected %s)'):format(token))
  ensure(token == current_token, ("expected '%s' got '%s'"):format(token, current_token))
  if not prevent_consume then return consume() end
end

local function look_ahead(n)
  return tokens[current_token_index + n]
end

local function look_past_surround(token_start_index)
  token_start_index = token_start_index or current_token_index
  local surround_start = tokens[token_start_index]
  local surround_end = C.SURROUND_ENDS[surround_start]
  local surround_depth = 1

  local look_ahead_token_index = token_start_index + 1
  local look_ahead_token = tokens[look_ahead_token_index]

  while surround_depth > 0 do
    if look_ahead_token == nil then
      throw(
        ("unexpected eof, missing ending '%s' for '%s' at [%d]"):format(
          surround_end,
          surround_start,
          token_lines[token_start_index]
        ),
        token_lines[look_ahead_token_index - 1]
      )
    elseif look_ahead_token == surround_start then
      surround_depth = surround_depth + 1
    elseif look_ahead_token == surround_end then
      surround_depth = surround_depth - 1
    end

    look_ahead_token_index = look_ahead_token_index + 1
    look_ahead_token = tokens[look_ahead_token_index]
  end

  return look_ahead_token, look_ahead_token_index
end

-- -----------------------------------------------------------------------------
-- Compile Helpers
-- -----------------------------------------------------------------------------

local function new_tmp_name()
  tmp_name_counter = tmp_name_counter + 1
  return ('__ERDE_TMP_%d__'):format(tmp_name_counter)
end

local function weave(t, separator)
  separator = separator or ','
  local woven = {}
  local len = #t

  for i = 1, len - 1 do
    insert(woven, t[i])
    if type(t[i]) ~= 'number' then
      insert(woven, separator)
    end
  end

  insert(woven, t[len])
  return woven
end

local function compile_binop(token, line, lhs, rhs)
  if bitlib and C.BITOPS[token] then
    local bitop = ('require("%s").%s('):format(bitlib, C.BITLIB_METHODS[token])
    return { line, bitop, lhs, line, ',', rhs, line, ')' }
  elseif token == '!=' then
    return { lhs, line, '~=', rhs }
  elseif token == '||' then
    return { lhs, line, 'or', rhs }
  elseif token == '&&' then
    return { lhs, line, 'and', rhs }
  elseif token == '//' then
    return (lua_target == '5.3' or lua_target == '5.3+' or lua_target == '5.4' or lua_target == '5.4+')
      and { lhs, line, token, rhs }
      or { line, 'math.floor(', lhs, line, '/', rhs, line, ')' }
  else
    return { lhs, line, token, rhs }
  end
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

local function list(callback, break_token)
  local list = {}

  repeat
    local item = callback()
    if item then table.insert(list, item) end
  until not branch(',') or (break_token and current_token == break_token)

  return list
end

local function surround(open_char, close_char, callback)
  expect(open_char)
  local result = callback()
  expect(close_char)
  return result
end

local function surround_list(open_char, close_char, callback, allow_empty)
  return surround(open_char, close_char, function()
    if current_token ~= close_char or not allow_empty then
      return list(callback, close_char)
    end
  end)
end

-- -----------------------------------------------------------------------------
-- Partials
-- -----------------------------------------------------------------------------

local function name(no_transform, allow_keywords)
  ensure(current_token ~= nil, 'unexpected eof')
  ensure(
    current_token:match('^[_a-zA-Z][_a-zA-Z0-9]*$'),
    ("unexpected token '%s'"):format(current_token)
  )

  if allow_keywords then
    for i, keyword in pairs(C.KEYWORDS) do
      ensure(current_token ~= keyword, ("unexpected keyword '%s'"):format(current_token))
    end
  end

  if C.LUA_KEYWORDS[current_token] and not no_transform then
    return ('__ERDE_SUBSTITUTE_%s__'):format(consume())
  end

  return consume()
end

local function destructure(scope)
  local names = {}
  local compile_lines = {}
  local compile_name = new_tmp_name()
  local assignment_prefix = scope == 'global' and '_G.' or ''

  if current_token == '[' then
    local array_index = 0
    surround_list('[', ']', function()
      local name_line, name = current_line, name()
      local assignment_name = assignment_prefix .. name
      array_index = array_index + 1

      insert(names, name)

      insert(compile_lines, name_line)
      insert(compile_lines, ('%s = %s[%s]'):format(assignment_name, compile_name, array_index))

      if branch('=') then
        insert(compile_lines, ('if %s == nil then %s = '):format(assignment_name, assignment_name))
        insert(compile_lines, expression())
        insert(compile_lines, 'end')
      end
    end)
  else
    surround_list('{', '}', function()
      -- Save `raw_key` in case `name()` transforms the word (Lua keywords)
      local key_line, raw_key, key = current_line, current_token, name()
      local name = branch(':') and name() or key
      local assignment_name = assignment_prefix .. name

      insert(names, name)

      insert(compile_lines, key_line)
      insert(compile_lines, ('%s = %s["%s"]'):format(assignment_name, compile_name, raw_key))

      if branch('=') then
        insert(compile_lines, ('if %s == nil then %s = '):format(assignment_name, assignment_name))
        insert(compile_lines, expression())
        insert(compile_lines, 'end')
      end
    end)
  end

  return {
    names = names,
    compile_name = compile_name,
    compile_lines = compile_lines,
  }
end

local function variable()
  return (current_token == '{' or current_token == '[')
    and destructure() or name()
end

local function index_chain(base_compile_lines, has_trivial_base, require_chain)
  local chain = {}
  local is_function_call = false
  local has_trivial_chain = false

  -- Variables for when we must compile to a Lua block.
  --
  -- There are cases where we cannot keep the compiled code as an expression and
  -- must compile to a block (such as a `do` block or an IIFE). One such case is
  -- when compiling a method index with a nontrivial base when the method name
  -- is a Lua keyword, but not an Erde keyword.
  local needs_block_compile = false
  local block_compile_name = new_tmp_name()
  local block_compile_lines = { 'local ' .. block_compile_name }

  while true do
    if current_token == '[' then
      has_trivial_chain = false
      insert(chain, { current_line, '[', surround('[', ']', expression), ']' })
    elseif current_token == '.' then
      has_trivial_chain = false

      local field_line = current_line
      consume()
      local field_name = name(true, true)

      if C.LUA_KEYWORDS[field_name] then
        insert(chain, { field_line, '["' .. field_name .. '"]' })
      else
        insert(chain, { field_line, '.' .. field_name })
      end
    elseif branch(':') then
      has_trivial_chain = false
      is_function_call = true

      local link = { current_line }
      local method_name = name(true, true)
      expect('(', true)

      if not C.LUA_KEYWORDS[method_name] then
        insert(link, ':' .. method_name)
      else
        local arg_compile_lines = surround_list('(', ')', expression, true)

        if has_trivial_base and has_trivial_chain then
          insert(link, '["' .. method_name .. '"](')
          insert(link, base_compile_lines)
        else
          needs_block_compile = true
          link.needs_intermediate = true
          insert(link, ('["%s"](%s'):format(method_name, block_compile_name))
        end

        if arg_compile_lines then
          insert(link, ',')
          insert(link, weave(arg_compile_lines))
        end

        insert(link, ')')
      end

      insert(chain, link)
    elseif current_token == '(' and current_line == token_lines[current_token_index - 1] then
      -- Use newlines to infer whether the parentheses belong to a function call
      -- or the next statement.
      has_trivial_chain = false
      is_function_call = true

      local chain_len = #chain
      local preceding_compile_lines, preceding_compile_lines_len

      if chain_len > 0 then
        preceding_compile_lines = chain[chain_len]
        preceding_compile_lines_len = #preceding_compile_lines
      else
        preceding_compile_lines = base_compile_lines
        preceding_compile_lines_len = #base_compile_lines

        while type(preceding_compile_lines[preceding_compile_lines_len]) == 'table' do
          preceding_compile_lines = preceding_compile_lines[preceding_compile_lines_len]
          preceding_compile_lines_len = #preceding_compile_lines
        end
      end

      local arg_compile_lines = surround_list('(', ')', expression, true)

      -- Include function call parens on same line as function name to prevent
      -- parsing errors in Lua5.1
      --    `ambiguous syntax (function call x new statement) near '('`
      if not arg_compile_lines then
        preceding_compile_lines[preceding_compile_lines_len] =
          preceding_compile_lines[preceding_compile_lines_len] .. '()'
      else
        preceding_compile_lines[preceding_compile_lines_len] =
          preceding_compile_lines[preceding_compile_lines_len] .. '('
        insert(chain, { weave(arg_compile_lines), ')' })
      end
    else
      break
    end
  end

  if require_chain and has_trivial_chain then
    if not current_token then
      throw('unexpected eof', last_line)
    else
      throw(("expected index chain, found '%s'"):format(current_token))
    end
  end

  for _, link in ipairs(chain) do
    if link.needs_intermediate then
      insert(block_compile_lines, block_compile_name .. '=')
      insert(block_compile_lines, base_compile_lines)
      base_compile_lines = { block_compile_name }
    end

    insert(base_compile_lines, link)
  end

  return {
    base_compile_lines = base_compile_lines,
    is_function_call = is_function_call,
    needs_block_compile = needs_block_compile,
    block_compile_name  = block_compile_name,
    block_compile_lines = block_compile_lines,
  }
end

local function return_list(require_list_parens)
  local compile_lines = {}

  if current_token ~= '(' then
    insert(compile_lines, require_list_parens and expression() or weave(list(expression)))
  else
    local look_ahead_limit_token, look_ahead_limit_token_index = look_past_surround()

    if look_ahead_limit_token == '->' or look_ahead_limit_token == '=>' then
      insert(compile_lines, expression())
    else
      local is_list = false

      for look_ahead_token_index = current_token_index + 1, look_ahead_limit_token_index - 1 do
        local look_ahead_token = tokens[look_ahead_token_index]

        if C.SURROUND_ENDS[look_ahead_token] then
          look_ahead_token, look_ahead_token_index = look_past_surround(look_ahead_token_index)
        end

        if look_ahead_token == ',' then
          is_list = true
          break
        end
      end

      insert(compile_lines, is_list and weave(surround_list('(', ')', expression)) or expression())
    end
  end

  return compile_lines
end

local function parameters()
  local compile_lines = {}
  local names = {}
  local has_varargs = false

  surround_list('(', ')', function()
    if branch('...') then
      has_varargs = true
      insert(names, '...')

      if current_token ~= ')' then
        insert(compile_lines, 'local ' .. name() .. ' = { ... }')
      end

      branch(',')
      expect(')', true)
    else
      local var = variable()
      local name = type(var) == 'string' and var or var.compile_name
      insert(names, name)

      if branch('=') then
        insert(compile_lines, ('if %s == nil then %s = '):format(name, name))
        insert(compile_lines, expression())
        insert(compile_lines, 'end')
      end

      if type(var) == 'table' then
        insert(compile_lines, 'local ' .. table.concat(var.names, ','))
        insert(compile_lines, var.compile_lines)
      end
    end
  end, true)

  return { names = names, compile_lines = compile_lines, has_varargs = has_varargs }
end

-- -----------------------------------------------------------------------------
-- Expressions
-- -----------------------------------------------------------------------------

local function arrow_function_expression()
  local compile_lines = {}
  local param_names = {}
  local old_is_varargs_block = is_varargs_block

  if current_token == '(' then
    local params = parameters()
    is_varargs_block = params.has_varargs
    param_names = params.names
    insert(compile_lines, params.compile_lines)
  else
    local var = variable()
    is_varargs_block = false
    if type(var) == 'string' then
      insert(param_names, var)
    else
      insert(param_names, var.compile_name)
      insert(compile_lines, 'local ' .. table.concat(var.names, ','))
      insert(compile_lines, var.compile_lines)
    end
  end

  if current_token == '->' then
    consume()
  elseif current_token == '=>' then
    insert(param_names, 1, 'self')
    consume()
  elseif current_token == nil then
    throw("unexpected eof (expected '->' or '=>')", token_lines[current_token_index - 1])
  else
    throw("unexpected token '%s' (expected '->' or '=>')")
  end

  insert(compile_lines, 1, 'function(' .. concat(param_names, ',') .. ')')

  if current_token == '{' then
    insert(compile_lines, surround('{', '}', function_block))
  else
    insert(compile_lines, { 'return', return_list(true) })
  end

  is_varargs_block = old_is_varargs_block
  insert(compile_lines, 'end')
  return compile_lines
end

local function index_chain_expression(...)
  local index_chain = index_chain(...)

  if not index_chain.needs_block_compile then
    return index_chain.base_compile_lines
  else
    return {
      '(function()',
      index_chain.block_compile_lines,
      'return',
      index_chain.base_compile_lines,
      'end)()',
    }
  end
end

local function interpolation_string_expression(start_quote, end_quote)
  local compile_lines = {}
  local content_line, content = current_line, consume()
  local is_block_string = start_quote:sub(1, 1) == '['

  if current_token == end_quote then
    -- Handle empty string case exceptionally so we can make assumptions at the
    -- end to simplify excluding empty string concatenations.
    insert(compile_lines, content .. consume())
    return compile_lines
  end

  repeat
    if current_token == '{' then
      if content ~= start_quote then -- only if nonempty
        insert(compile_lines, content_line)
        insert(compile_lines, content .. end_quote)
      end

      insert(compile_lines, { 'tostring(', surround('{', '}', expression), ')' })
      content_line, content = current_line, start_quote

      if is_block_string and current_token:sub(1, 1) == '\n' then
        -- Lua ignores the first character in block strings when it is a
        -- newline! We need to make sure we preserve any newline following
        -- an interpolation by inserting a second newline in the compiled code.
        -- @see http://www.lua.org/pil/2.4.html
        content = content .. '\n' .. consume()
      end
    else
      content = content .. consume()
    end
  until current_token == end_quote

  if content ~= start_quote then -- only if nonempty
    insert(compile_lines, content_line)
    insert(compile_lines, content .. end_quote)
  end

  consume() -- end_quote
  return weave(compile_lines, '..')
end

local function single_quote_string_expression()
  local content_line, content = current_line, consume()

  if current_token ~= "'" then
    content = content .. consume()
  end

  content = content .. consume()
  return { content_line, content }
end

local function table_expression()
  local compile_lines = {}

  surround_list('{', '}', function()
    if current_token == '[' then
      insert(compile_lines, '[')
      insert(compile_lines, surround('[', ']', expression))
      insert(compile_lines, ']')
      insert(compile_lines, expect('='))
    elseif look_ahead(1) == '=' then
      local key = name(true)
      if C.LUA_KEYWORDS[key] then
        insert(compile_lines, '["' .. key .. '"]' .. consume())
      else
        insert(compile_lines, key .. consume())
      end
    end

    insert(compile_lines, expression())
    insert(compile_lines, ',')
  end, true)

  return { '{', compile_lines, '}' }
end

local function terminal_expression()
  ensure(current_token ~= nil, 'unexpected eof')
  ensure(current_token ~= '...' or is_varargs_block, "cannot use '...' outside a vararg function")

  for _, terminal in pairs(C.TERMINALS) do
    if current_token == terminal then
      return { current_line, consume() }
    end
  end

  if C.DIGIT[current_token:sub(1, 1)] then
    return { current_line, consume() }
  elseif current_token == "'" then
    local terminal_line = current_line
    local string_line, erde_string = current_line, consume()

    if current_token ~= "'" then
      erde_string = erde_string .. consume()
    end

    erde_string = erde_string .. consume()
    return index_chain_expression({ '(', erde_string, ')' }, true)
  elseif current_token == '"' then
    -- TODO: check for interpolation to determine index_chain.has_trivial_base?
    return index_chain_expression({ '(', interpolation_string_expression('"', '"'), ')' }, false)
  elseif current_token:match('^%[[[=]') then
    -- TODO: check for interpolation to determine index_chain.has_trivial_base?
    return index_chain_expression({ '(', interpolation_string_expression(current_token, current_token:gsub('%[', ']')), ')' }, false)
  end

  local next_token = look_ahead(1)
  local is_arrow_function = next_token == '->' or next_token == '=>'

  -- First do a quick check for is_arrow_function (in case of implicit params),
  -- otherwise if surround_end is truthy (possible params), need to check the
  -- next token after. This is _much_ faster than backtracking.
  if not is_arrow_function and C.SURROUND_ENDS[current_token] then
    local past_surround_token = look_past_surround()
    is_arrow_function = past_surround_token == '->' or past_surround_token == '=>'
  end

  if is_arrow_function then
    return arrow_function_expression()
  elseif current_token == '{' then
    return table_expression()
  elseif current_token == '(' then
    return index_chain_expression({ '(', surround('(', ')', expression), ')' }, false)
  else
    return index_chain_expression({ current_line, name() }, true)
  end
end

local function unop_expression()
  local compile_lines  = {}
  local unop_line, unop = current_line, C.UNOPS[consume()]
  local operand_line, operand = current_line, expression(unop.prec + 1)

  if unop.token == '~' then
    if bitlib then
      local bitop = ('require("%s").%s('):format(bitlib, 'bnot')
      return { unop_line, bitop, operand_line, operand, unop_line, ')' }
    elseif lua_target == '5.1+' or lua_target == '5.2+' then
      throw('must specify bitlib for compiling bit operations when targeting 5.1+ or 5.2+', unop_line)
    else
      return { unop_line, unop.token, operand_line, operand }
    end
  elseif unop.token == '!' then
    return { unop_line, 'not', operand_line, operand }
  else
    return { unop_line, unop.token, operand_line, operand }
  end
end

function expression(min_prec)
  min_prec = min_prec or 1

  local compile_lines = C.UNOPS[current_token] and unop_expression() or terminal_expression()
  local binop = C.BINOPS[current_token]

  while binop and binop.prec >= min_prec do
    local binop_line = current_line
    consume()

    local rhs_min_prec = binop.prec
    if binop.assoc == C.LEFT_ASSOCIATIVE then
      rhs_min_prec = rhs_min_prec + 1
    end

    if C.BITOPS[binop.token] and (lua_target == '5.1+' or lua_target == '5.2+') and not bitlib then
      throw('must specify bitlib for compiling bit operations when targeting 5.1+ or 5.2+', binop_line)
    end

    compile_lines = compile_binop(binop.token, binop_line, compile_lines, expression(rhs_min_prec))
    binop = C.BINOPS[current_token]
  end

  return compile_lines
end

-- -----------------------------------------------------------------------------
-- Statements
-- -----------------------------------------------------------------------------

local function assignment_statement(first_id)
  local compile_lines = {}
  local index_chains = { first_id }
  local base_compile_lines = { first_id.base_compile_lines }
  local needs_block_compile = first_id.needs_block_compile

  while branch(',') do
    local index_chain_line = current_line
    local index_chain = current_token == '('
      and index_chain({ '(', surround('(', ')', expression), ')' }, false, true)
      or index_chain({ name() }, true)

    if index_chain.is_function_call then
      throw('cannot assign value to function call', index_chain_line)
    end

    needs_block_compile = needs_block_compile or index_chain.needs_block_compile
    insert(index_chains, index_chain)
    insert(base_compile_lines, index_chain.base_compile_lines)
  end

  local op_line, op_token = current_line, C.BINOP_ASSIGNMENT_TOKENS[current_token] and consume()
  if C.BITOPS[op_token] and (lua_target == '5.1+' or lua_target == '5.2+') and not bitlib then
    throw('must specify bitlib for compiling bit operations when targeting 5.1+ or 5.2+', op_line)
  end

  expect('=')
  local expr_list = list(expression)

  -- Optimize most common use cases
  if not needs_block_compile and not op_token then
    insert(compile_lines, weave(base_compile_lines))
    insert(compile_lines, '=')
    insert(compile_lines, weave(expr_list))
  elseif not needs_block_compile and #index_chains == 1 then
    insert(compile_lines, first_id.base_compile_lines)
    insert(compile_lines, op_line)
    insert(compile_lines, '=')
    insert(compile_lines, compile_binop(op_token, op_line, first_id.base_compile_lines, expr_list[1]))
  else
    local assignment_names = {}
    local assignment_compile_lines = {}

    for i, id in ipairs(index_chains) do
      local assignment_name = new_tmp_name()
      insert(assignment_names, assignment_name)

      if id.needs_block_compile then
        insert(assignment_compile_lines, id.block_compile_lines)
      end

      insert(assignment_compile_lines, id.base_compile_lines)
      insert(assignment_compile_lines, '=')
      insert(assignment_compile_lines, op_token
        and compile_binop(op_token, op_line, id.base_compile_lines, assignment_name)
        or assignment_name
      )
    end

    insert(compile_lines, 'do')
    insert(compile_lines, 'local')
    insert(compile_lines, concat(assignment_names, ','))
    insert(compile_lines, '=')
    insert(compile_lines, weave(expr_list))
    insert(compile_lines, assignment_compile_lines)
    insert(compile_lines, 'end')
  end

  return compile_lines
end

local function break_statement()
  ensure(break_name ~= nil, "cannot use 'break' outside of loop")
  return { current_line, consume() }
end

local function continue_statement()
  ensure(break_name ~= nil, "cannot use 'continue' outside of loop")

  has_continue = true
  consume()

  return (lua_target == '5.1' or lua_target == '5.1+')
    and { break_name .. ' = false break' }
    or { 'goto ' .. break_name }
end

local function declaration_statement()
  local scope = consume()

  local compile_lines = {}
  local destructure_compile_lines = {}

  local declaration_names = {}
  local destructure_compile_names = {}
  local assignment_names = {}

  if block_depth > 1 and scope == 'module' then
    throw('module declarations must appear at the top level', token_lines[current_token_index - 1])
  end

  for _, var in ipairs(list(function() return variable(scope) end)) do
    if type(var) == 'string' then
      insert(declaration_names, var)
      insert(assignment_names, (scope == 'global' and '_G.' or '') .. var)
    else
      insert(assignment_names, var.compile_name)
      insert(destructure_compile_names, var.compile_name)
      insert(destructure_compile_lines, var.compile_lines)

      for _, name in ipairs(var.names) do
        insert(declaration_names, name)
      end
    end
  end

  if scope == 'module' then
    for _, declaration_name in ipairs(declaration_names) do
      module_names[declaration_name] = true
    end
  end

  if scope ~= 'global' then
    insert(compile_lines, 'local ' .. table.concat(declaration_names, ','))
  end

  if branch('=') then
    if #destructure_compile_names > 0 then
      insert(compile_lines, 'do')
      insert(compile_lines, 'local ' .. table.concat(destructure_compile_names, ','))
      insert(compile_lines, table.concat(assignment_names, ',') .. '=')
      insert(compile_lines, weave(list(expression)))
      insert(compile_lines, destructure_compile_lines)
      insert(compile_lines, 'end')
    elseif scope == 'global' then
      insert(compile_lines, table.concat(assignment_names, ',') .. '=')
      insert(compile_lines, weave(list(expression)))
    else
      insert(compile_lines, '=')
      insert(compile_lines, weave(list(expression)))
    end
  end

  return compile_lines
end

local function do_statement()
  local compile_lines = {}

  insert(compile_lines, consume())
  insert(compile_lines, surround('{', '}', block))
  insert(compile_lines, 'end')

  return compile_lines
end

local function for_loop_statement()
  local compile_lines = { consume() }
  local pre_body_compile_lines = {}

  if look_ahead(1) == '=' then
    insert(compile_lines, current_line)
    insert(compile_lines, name())

    insert(compile_lines, current_line)
    insert(compile_lines, consume())

    local expr_list_line = current_line
    local expr_list = list(expression)
    local expr_list_len = #expr_list

    if expr_list_len < 2 then
      throw('missing loop parameters (must supply 2-3 params)', expr_list_line)
    elseif expr_list_len > 3 then
      throw('too many loop parameters (must supply 2-3 params)', expr_list_line)
    end

    insert(compile_lines, weave(expr_list))
  else
    local names = {}

    for i, var in ipairs(list(variable)) do
      if type(var) == 'string' then
        insert(names, var)
      else
        insert(names, var.compile_name)
        insert(pre_body_compile_lines, 'local ' .. table.concat(var.names, ','))
        insert(pre_body_compile_lines, var.compile_lines)
      end
    end

    insert(compile_lines, weave(names))
    insert(compile_lines, expect('in'))

    -- Generic for parses an expression list!
    -- see https://www.lua.org/pil/7.2.html
    -- TODO: only allow max 3 expressions? Job for linter?
    insert(compile_lines, weave(list(expression)))
  end

  insert(compile_lines, 'do')
  insert(compile_lines, pre_body_compile_lines)
  insert(compile_lines, surround('{', '}', loop_block))
  insert(compile_lines, 'end')

  return compile_lines
end

local function function_statement()
  local compile_lines = {}
  local scope_line, scope = current_line, nil

  if current_token == 'local' or current_token == 'global' or current_token == 'module' then
    scope = consume()
    insert(compile_lines, consume()) -- 'function'
  elseif current_token == 'function' then
    insert(compile_lines, consume())
  else
    throw(("unexpected token '%s' (expected scope)"):format(current_token))
  end

  local signature = name()
  local is_table_value = current_token == '.'

  if scope == 'global' then
    signature = '_G.' .. signature
    is_table_value = true
  end

  while branch('.') do
    signature = signature .. '.' .. name()
  end

  if branch(':') then
    is_table_value = true
    signature = signature .. ':' .. name()
  end

  if not is_table_value then
    -- Default to local scope (this includes when scope is undefined!)
    insert(compile_lines, 1, 'local')
  elseif scope == 'local' or scope == 'module' then
    -- Lua does not allow scope for table functions (ex. `local function a.b()`)
    throw('cannot use scopes for table values', scope_line)
  end

  if scope == 'module' then
    if block_depth > 1 then
      throw('module declarations must appear at the top level', scope_line)
    end

    module_names[signature] = true
  end

  insert(compile_lines, signature)

  local params = parameters()
  insert(compile_lines, '(' .. concat(params.names, ',') .. ')')
  insert(compile_lines, params.compile_lines)

  local old_is_varargs_block = is_varargs_block
  is_varargs_block = params.has_varargs
  insert(compile_lines, surround('{', '}', function_block))
  is_varargs_block = old_is_varargs_block

  insert(compile_lines, 'end')
  return compile_lines
end

local function goto_jump_statement()
  local compile_lines = {}

  if lua_target == '5.1' or lua_target == '5.1+' then
    throw("'goto' statements only compatibly with lua targets 5.2+, jit")
  end

  insert(compile_lines, current_line)
  insert(compile_lines, consume())
  insert(compile_lines, current_line)
  insert(compile_lines, name())

  return compile_lines
end

local function goto_label_statement()
  local compile_lines = {}

  if lua_target == '5.1' or lua_target == '5.1+' then
    throw("'goto' statements only compatibly with lua targets 5.2+, jit")
  end

  insert(compile_lines, current_line)
  insert(compile_lines, consume() .. name() .. expect('::'))

  return compile_lines
end

local function if_else_statement()
  local compile_lines = {}

  insert(compile_lines, consume())
  insert(compile_lines, expression())
  insert(compile_lines, 'then')
  insert(compile_lines, surround('{', '}', block))

  while current_token == 'elseif' do
    insert(compile_lines, consume())
    insert(compile_lines, expression())
    insert(compile_lines, 'then')
    insert(compile_lines, surround('{', '}', block))
  end

  if current_token == 'else' then
    insert(compile_lines, consume())
    insert(compile_lines, surround('{', '}', block))
  end

  insert(compile_lines, 'end')
  return compile_lines
end

local function repeat_until_statement()
  local compile_lines = {}

  insert(compile_lines, consume())
  insert(compile_lines, surround('{', '}', loop_block))
  insert(compile_lines, expect('until'))
  insert(compile_lines, expression())

  return compile_lines
end

local function return_statement()
  local compile_lines = { current_line, consume() }

  if is_module_return_block then
    has_module_return = true
  end

  if block_depth == 1 then
    if current_token then
      insert(compile_lines, return_list())
    end

    if current_token then
      throw(("expected '<eof>', got '%s'"):format(current_token))
    end
  else
    if current_token ~= '}' then
      insert(compile_lines, return_list())
    end

    if current_token ~= '}' then
      throw(("expected '}', got '%s'"):format(current_token))
    end
  end

  return compile_lines
end

local function while_loop_statement()
  local compile_lines = {}

  insert(compile_lines, consume())
  insert(compile_lines, expression())
  insert(compile_lines, 'do')
  insert(compile_lines, surround('{', '}', loop_block))
  insert(compile_lines, 'end')

  return compile_lines
end

local function statement()
  local compile_lines = {}

  if current_token == 'break' then
    insert(compile_lines, break_statement())
  elseif current_token == 'continue' then
    insert(compile_lines, continue_statement())
  elseif current_token == 'goto' then
    insert(compile_lines, goto_jump_statement())
  elseif current_token == '::' then
    insert(compile_lines, goto_label_statement())
  elseif current_token == 'do' then
    insert(compile_lines, do_statement())
  elseif current_token == 'if' then
    insert(compile_lines, if_else_statement())
  elseif current_token == 'for' then
    insert(compile_lines, for_loop_statement())
  elseif current_token == 'while' then
    insert(compile_lines, while_loop_statement())
  elseif current_token == 'repeat' then
    insert(compile_lines, repeat_until_statement())
  elseif current_token == 'return' then
    insert(compile_lines, return_statement())
  elseif current_token == 'function' or look_ahead(1) == 'function' then
    insert(compile_lines, function_statement())
  elseif current_token == 'local' or current_token == 'global' or current_token == 'module' then
    insert(compile_lines, declaration_statement())
  else
    local index_chain = current_token == '('
      and index_chain({ current_line, '(', surround('(', ')', expression), ')' }, false, true)
      or index_chain({ current_line, name() }, true)

    if not index_chain.is_function_call then
      insert(compile_lines, assignment_statement(index_chain))
    elseif not index_chain.needs_block_compile then
      insert(compile_lines, index_chain.base_compile_lines)
    else
      insert(compile_lines, {
        '(function()',
        index_chain.block_compile_lines,
        'return',
        index_chain.base_compile_lines,
        'end)()',
      })
    end
  end

  if current_token == ';' then
    insert(compile_lines, consume())
  elseif current_token == '(' then
    -- Add semi-colon to prevent ambiguous Lua code
    insert(compile_lines, ';')
  end

  return compile_lines
end

-- -----------------------------------------------------------------------------
-- Blocks
-- -----------------------------------------------------------------------------

function block()
  local compile_lines = {}
  block_depth = block_depth + 1

  while current_token ~= '}' do
    insert(compile_lines, statement())
  end

  block_depth = block_depth - 1
  return compile_lines
end

function loop_block()
  local old_break_name = break_name
  local old_has_continue = has_continue

  break_name = new_tmp_name()
  has_continue = false

  local compile_lines = block()

  if has_continue then
    if lua_target == '5.1' or lua_target == '5.1+' then
      insert(compile_lines, 1, ('local %s = true repeat'):format(break_name))
      insert(
        compile_lines,
        ('%s = false until true if %s then break end'):format(break_name, break_name)
      )
    else
      insert(compile_lines, '::' .. break_name .. '::')
    end
  end

  break_name = old_break_name
  has_continue = old_has_continue

  return compile_lines
end

function function_block()
  local old_is_module_return_block = is_module_return_block
  local old_break_name = break_name

  is_module_return_block = false
  break_name = nil

  local compile_lines = block()

  is_module_return_block = old_is_module_return_block
  break_name = old_break_name

  return compile_lines
end

local function module_block(options)
  local compile_lines = {}

  if current_token:match('^#!') then
    insert(compile_lines, consume())
  end

  while current_token ~= nil do
    insert(compile_lines, statement())
  end

  if has_module_return then
    if #module_names > 0 then
      throw("cannot use 'module' declarations w/ 'return'", last_line)
    end
  elseif not options.no_module then
    insert(compile_lines, 1, 'local _MODULE = {}')

    for name in pairs(module_names) do
      insert(compile_lines, ('_MODULE["%s"] = %s'):format(name, name))
    end

    insert(compile_lines, 'return _MODULE')
  end

  return compile_lines
end

-- -----------------------------------------------------------------------------
-- Main
-- -----------------------------------------------------------------------------

return function(source, options)
  options = options or {}

  local tokenize_state = tokenize(source, options.alias)
  tokens = tokenize_state.tokens
  token_lines = tokenize_state.token_lines
  num_tokens = tokenize_state.num_tokens

  -- Check for empty file or file w/ only comments
  if num_tokens == 0 then
    return table.concat({
      '-- Compiled with Erde ' .. C.VERSION,
      C.COMPILED_FOOTER_COMMENT,
    }, '\n'), {}
  end

  current_token, current_token_index = tokens[1], 1
  current_line, last_line = token_lines[1], token_lines[num_tokens]

  block_depth = 1
  is_module_return_block = true
  has_module_return = false
  has_continue = false
  is_varargs_block = true
  tmp_name_counter = 1
  module_names = {}

  alias = options.alias or utils.get_source_alias(source)
  lua_target = options.lua_target or C.LUA_TARGET
  bitlib = options.bitlib or C.BITLIB
    or (lua_target == '5.1' and 'bit') -- Mike Pall's LuaBitOp
    or (lua_target == 'jit' and 'bit') -- Mike Pall's LuaBitOp
    or (lua_target == '5.2' and 'bit32') -- Lua 5.2's builtin bit32 library


  local compile_lines = module_block(options)

  local collapsed_compile_lines = {}
  local collapsed_compile_line_counter = 0
  local source_map = {}

  -- Assign compiled lines with no source to the last known source line. We do
  -- this because Lua may give an error at the line of the _next_ token in
  -- certain cases. For example, the following will give an error at line 3,
  -- instead of line 2 where the nil index actually occurs:
  --   local x = nil
  --   print(x.a
  --   )
  local source_line = token_lines[1]

  local function collect_lines(lines)
    for _, line in ipairs(lines) do
      if type(line) == 'number' then
        source_line = line
      elseif type(line) == 'string' then
        insert(collapsed_compile_lines, line)
        collapsed_compile_line_counter = collapsed_compile_line_counter + 1
        source_map[collapsed_compile_line_counter] = source_line
      else
        collect_lines(line)
      end
    end
  end

  collect_lines(compile_lines)
  insert(collapsed_compile_lines, '-- Compiled with Erde ' .. C.VERSION)
  insert(collapsed_compile_lines, C.COMPILED_FOOTER_COMMENT)

  -- Free resources (potentially large tables)
  tokens, token_lines = nil, nil

  return concat(collapsed_compile_lines, '\n'), source_map
end
