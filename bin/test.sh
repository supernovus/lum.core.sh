#!/bin/bash

LUM_CORE_TEST_SH="$(realpath -e "$0")"
LUM_CORE_BIN_DIR="$(dirname "$LUM_CORE_TEST_SH")"
LUM_CORE_PKG_DIR="$(dirname "$LUM_CORE_BIN_DIR")"

declare -i LUM_SHELL_RESTART=1 LUM_SHELL_DEBUG=0

## Extremely basic debugging
+lts() {
  local -i TV="$1"
  [ "$LUM_SHELL_DEBUG" -ge $TV ] && echo "«lts:$2»" "${@:3}" >&2
}

while [ $LUM_SHELL_RESTART -eq 1 ]; do
  ## This loop exists to reload the process libraries.
  +lts 1 "init-loop-start"
  . $LUM_CORE_PKG_DIR/lib/core.sh
  +lts 1 "init-loop-post-source"
  lum::use lum::test::shell 
  +lts 1 "init-loop-post-use"
  lum::test::shell "$@"
  +lts 1 "init-loop-end"
done 
