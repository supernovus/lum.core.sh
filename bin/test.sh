#!/bin/bash

LUM_CORE_BIN_DIR="$(dirname $0)"
LUM_USAGE_TITLE="Usage: "

. $LUM_CORE_BIN_DIR/../lib/core.sh

lum::use lum::themes::default lum::tmpl

declare -a LUM_TEST_CMDS

lum::fn test.sh 2 -t 0 8
#$ <<command>> `{...}` 
#
#Commands:
#@>lum::tmpl;
#{{lum::test::list}}
#
#: test.sh

lum::fn::alias lum::help --help 1 LUM_TEST_CMDS
lum::fn::alias lum::help help

lum::fn lum::test::list 0 -a --list 1 LUM_TEST_CMDS -a list 0 0
#$ `{--}`
#
# List known commands
#
lum::test::list() {
  lum::help::list LUM_TEST_CMDS 20 "-" " '" "'"
}

if [ $# -lt 1 ]; then
  echo -n "Usage: "
  lum::help test.sh
  exit 1
fi

lum::fn::run 1 "$@"
