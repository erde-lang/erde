#!/usr/bin/env bash

# Escape the '+' in the targets! Internally, busted uses `name:find('#' .. tag)`
# and thus '+' will be interpreted as a pattern. For example, this means that
# the '5.1+' tag will also run '5.1' tags.
declare -A LUA_TARGET_TAGS=(
  ["jit"]="jit,5.1%+"
  ["5.1"]="5.1,5.1%+"
  ["5.1+"]="5.1%+"
  ["5.2"]="5.2,5.1%+,5.2%+"
  ["5.2+"]="5.1%+,5.2%+"
  ["5.3"]="5.3,5.1%+,5.2%+,5.3%+"
  ["5.3+"]="5.1%+,5.2%+,5.3%+"
  ["5.4"]="5.4,5.1%+,5.2%+,5.3%+,5.4%+"
  ["5.4+"]="5.1%+,5.2%+,5.3%+,5.4%+"
)

function spec {
  echo "$1 targeting $2"
  LUA_TARGET="$2" busted --lua="/usr/bin/$1" --tags="${LUA_TARGET_TAGS[$2]}"
  echo
}

spec luajit "jit"
spec luajit 5.1+

spec lua5.1 5.1
spec lua5.1 5.1+

spec lua5.2 5.2
spec lua5.2 5.1+
spec lua5.2 5.2+

spec lua5.3 5.3
spec lua5.3 5.1+
spec lua5.3 5.2+
spec lua5.3 5.3+

spec lua5.4 5.4
spec lua5.4 5.1+
spec lua5.4 5.2+
spec lua5.4 5.3+
spec lua5.4 5.4+
