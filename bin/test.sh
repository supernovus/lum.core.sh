#!/bin/bash

LUM_CORE_TEST_SH="$(realpath -e "$0")"
LUM_CORE_BIN_DIR="$(dirname "$LUM_CORE_TEST_SH")"
LUM_CORE_PKG_DIR="$(dirname "$LUM_CORE_BIN_DIR")"

declare -i LUM_SHELL_RESTART=1 LUM_SHELL_DEBUG

## Extremely basic debugging
+lts() {
  [ $LUM_SHELL_DEBUG != 0 ] &&  echo "«lts:$1»" "${@:2}" >&2
}

while [ $LUM_SHELL_RESTART -eq 1 ]; do
  ## This loop exists to reload the process libraries.
  +lts "init-loop-start"
  . $LUM_CORE_PKG_DIR/lib/core.sh
  +lts "init-loop-post-source"
  lum::use lum::test::shell 
  +lts "init-loop-post-use"
  lum::test::shell "$@"
  +lts "init-loop-end"
done 
