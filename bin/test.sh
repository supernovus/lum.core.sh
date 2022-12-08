#!/bin/bash

LUM_USAGE_TITLE="Usage: "
LUM_USAGE_STACK=1
LUM_ERR_EXIT=0

LUM_CORE_BIN_DIR="$(realpath -e "$(dirname "$0")")"
LUM_CORE_PKG_DIR="$(dirname "$LUM_CORE_BIN_DIR")"

. $LUM_CORE_PKG_DIR/lib/core.sh

lum::use lum::themes::default lum::use::pkg 

declare -n LT="LUM_THEME"

LUM_TEST_MODE=0
LUM_TEST_HISTORY="$HOME/.lum-core-test-history"

echo "${LT[help.header]}lumsh${LT[end]}" 
echo "${LT[help.syntax]}for help: ${LT[help.value]}//h${LT[end]}"

history -r "$LUM_TEST_HISTORY"

while true; do 
  #echo -n "[$LUM_TEST_MODE]> "
  read -e -p "[$LUM_TEST_MODE]> " line
  history -s "$line"
  case "$line" in
    //q)
      break
    ;;
    //Q)
      exit
    ;;
    //H)
      history
    ;;
    //h)
      echo "TODO"
    ;;
    //*)
      LUM_TEST_MODE="${line/\/\/}"
    ;;
    *)
      case "$LUM_TEST_MODE" in
        0|1|2|3)
          lum::fn::run $LUM_TEST_MODE $line
        ;;
        E)
          eval "$line"
        ;;
        e)
          echo -e "$line"
        ;;
      esac
    ;;
  esac
done 

history -w "$LUM_TEST_HISTORY"
