#!/bin/bash

LUM_CORE_BIN_DIR="$(dirname $0)"
LUM_USAGE_TITLE="Usage: "
LUM_USAGE_STACK=1

. $LUM_CORE_BIN_DIR/../lib/core.sh

lum::use lum::themes::default 
lum::use lum::tmpl lum::args lum::getopts lum::user

declare -a LUM_TEST_CMDS

lum::fn doc-test 4
#$ Doc test
# First line,
# second line;
# last line.

lum::fn lum::test-usage 2 -t 0 24 -a $SCRIPTNAME 1 0
#$ <<command>> `{...}` 
#
#Commands for ${SCRIPTNAME}:
#@>lum::tmpl;
#{{lum::test::list}}
#
#: lum::test-usage

lum::fn::alias lum::help --help 1 LUM_TEST_CMDS
lum::fn::alias lum::help help
lum::fn::alias lum::user::conf --userconf 0 LUM_TEST_CMDS
lum::fn::alias lum::fn::list --funcs 1 LUM_TEST_CMDS
lum::fn::alias lum::fn::list funcs

lum::fn lum::test::list 4 -a --cmds 1 LUM_TEST_CMDS -a cmds 0 0
#$ - List known commands.
lum::test::list() {
  local listName="${1:-LUM_TEST_CMDS}"
  lum::help::list "$listName"
}

lum::fn lum::test::topics 0 -a --topics 1 LUM_TEST_CMDS -a topics 0 0
#$ [[find]]
#
# Show registered functions and help topics
#
lum::test::topics() {
  lum::help::topics 1 "$1"
}

lum::fn lum::test::aliases 0 -a --aliases 1 LUM_TEST_CMDS -a aliases 0 0
#$ [[find]]
#
# Show registered aliases
#
lum::test::aliases() {
  lum::help::topics 2 "$1"
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
