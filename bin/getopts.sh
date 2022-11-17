#!/bin/bash

LUM_CORE_BIN_DIR="$(dirname $0)"
LUM_USAGE_STACK=1
LUM_FN_DEBUG=0

. $LUM_CORE_BIN_DIR/../lib/core.sh

lum::use lum::themes::default
lum::use lum::getopts

lum::getopts atest

atest::def v verbose '#' n name ':' D debug '?' o opts '+'
atest::parse 1 "$@"

oname="$(atest::opts)"

declare -n parsed="$(atest::opts)"
declare -n arrayOpts="$(atest::lists)"
declare -n positional="$(atest::args)"

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
