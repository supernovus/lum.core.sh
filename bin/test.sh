#!/bin/bash

LUM_CORE_BIN_DIR="$(dirname $0)"
LUM_USAGE_TITLE="Usage: "

. $LUM_CORE_BIN_DIR/../lib/core.sh

lum::use lum::themes::default lum::tmpl

declare -a LUM_TEST_CMDS

lum::fn lum::test-usage 2 -t 0 8 -a $SCRIPTNAME 1 0
#$ <<command>> `{...}` 
#
#Commands:
#@>lum::tmpl;
#{{lum::test::list}}
#
#: lum::test-usage

lum::fn::alias lum::help --help 1 LUM_TEST_CMDS
lum::fn::alias lum::help help

lum::fn lum::test::list 0 -a --list 1 LUM_TEST_CMDS -a list 0 0
#$ [[prefix]]
#
# List known commands.
#
# ((prefix))    Optional prefix for commands.
#           If specified, this calls ``lum::fn::list``.
#           If not used, this calls ``lum::help::list``.
#
lum::test::list() {
  if [ $# -eq 0 ]; then
    lum::help::list LUM_TEST_CMDS 20 "-" " '" "'"
  else
    lum::fn::list "$@"
  fi
}

lum::fn lum::test::usage 0 -a --usage 1 LUM_TEST_CMDS -a usage 0 0
#$ `{...}`
#
# Show script usage information.
#
lum::test::usage() {
  echo -n "Usage: "
  lum::help lum::test-usage
  exit 1
}

[ $# -eq 0 ] && lum::test::usage

lum::fn::run 1 "$@"
