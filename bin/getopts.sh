#!/bin/bash

LUM_CORE_BIN_DIR="$(dirname $0)"
LUM_USAGE_STACK=1
LUM_FN_DEBUG=0

. "$LUM_CORE_BIN_DIR/../lib/core.sh"

lum::fn getopts-usage 2
#$ [[options...]] [[positionalArgs...]]
#
# Flag      Name          Type          Description
#
# ``-v``      ``verbose``     ``#``           Numeric option example
# ``-n``      ``name``        ``:``           Mandatory value option example
# ``-D``      ``debug``       ``?``           Optional value option example
# ``-o``      ``opts``        ``+``           First list option example
# ``-a``      ``vals``        ``+``           Second list option example
#
# ``-A``      ``get``         ``+``           Variable names to show:
#                                       ``opts args lists +opts +vals +get``
#
# ``-h``      ``help``        ``#``           Show this help text if used.
#
#: getopts-usage

lum::use lum::themes::default
lum::use lum::getopts

lum::getopts atest

atest::def v verbose '#' n name ':' D debug '?' o opts '+' a vals '+' A get '+' h help '#'
atest::parse 1 "$@"

declare -n parsed="$(atest::opts)"

if [ -n "${parsed[help]}" -a "${parsed[help]}" != "0" ]; then
  lum::help getopts-usage
  exit
fi

declare -n arrayOpts="$(atest::lists)"
declare -n positional="$(atest::args)"

declare -n showVars="$(atest::+get)"

echo "Parsed Arguments"

echo " |- Named (single value)"
for key in "${!parsed[@]}"; do 
  echo " |  |- $key=${parsed[$key]}"
done

echo " |- Named (multiple values)"
for key in "${!arrayOpts[@]}"; do
  echo " |  |- $key"
  declare -n anArray="${arrayOpts[$key]}"
  for val in "${anArray[@]}"; do
    echo " |  |  |- $val"
  done
done

echo " |- Positional"
for val in "${positional[@]}"; do 
  echo " |  |- $val"
done 

echo " |- Requested Variables [${#showVars[@]}]"
for val in "${showVars[@]}"; do
  [ "$val" = "def" -o "$val" = "parse" ] && lum::err "'$val' is not allowed"
  lum::fn::is "atest::$val" || lum::err "no such var '$val'"
  echo " |  |- $(atest::$val)"
done

echo "For usage type: $0 -h"