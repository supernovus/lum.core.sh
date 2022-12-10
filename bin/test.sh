#!/bin/bash

LUM_CORE_TEST_SH="$(realpath -e "$0")"
LUM_CORE_BIN_DIR="$(dirname "$LUM_CORE_TEST_SH")"
LUM_CORE_PKG_DIR="$(dirname "$LUM_CORE_BIN_DIR")"

declare -i LUM_SHELL_RESTART=1

while [ $LUM_SHELL_RESTART -eq 1 ]; do
  ## This loop exists to reload the process libraries.
  . $LUM_CORE_PKG_DIR/lib/core.sh
  lum::use lum::test::shell 
  lum::test::shell "$@"
done 
