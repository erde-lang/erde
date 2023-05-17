local state = require('erde.tokenize.state')

local _MODULE = {}

function _MODULE.commit(token, line)
  state.num_tokens = state.num_tokens + 1
  state.tokens[state.num_tokens] = token
  state.token_lines[state.num_tokens] = line or state.current_line
end

function _MODULE.consume(n)
  n = n or 1
  local consumed = n == 1 and state.char or _MODULE.peek(n)
  state.char_index = state.char_index + n
  state.char = state.text:sub(state.char_index, state.char_index)
  return consumed
end

function _MODULE.look_ahead(n)
  return state.text:sub(state.char_index + n, state.char_index + n)
end

function _MODULE.peek(n)
  return state.text:sub(state.char_index, state.char_index + n - 1)
end

function _MODULE.throw(message, line)
  -- Use error level 0 since we already include `source_name`
  error(('%s:%d: %s'):format(state.source_name, line or state.current_line, message), 0)
end

return _MODULE
