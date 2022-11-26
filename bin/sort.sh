#!/bin/bash

LUM_CORE_BIN_DIR="$(dirname $0)"

. $LUM_CORE_BIN_DIR/../lib/core.sh

lum::fn sort-usage 2
#$ [[sortOpts...]] `{--}` <<values...>>
#
# Sort a bunch of values
#
# ((sortOpts))       Options for the ``sort`` command.
#                  
# ((values))         The values to sort.
#
# The ((sortOpts)) and ((values)) **must** be separated with ``--``.
#
#: sort-usage

lum::use lum::themes::default

declare -a SORTOPTS

while [ $# -gt 0 ]; do
  if [ "$1" = '--' ]; then
    shift
    break
  fi
  SORTOPTS+=("$1")
  shift
done

[ $# -eq 0 ] && lum::help sort-usage

declare -a SORTED UNSORTED=("$@")

lum::var::sort UNSORTED SORTED "${SORTOPTS[@]}"

for item in "${SORTED[@]}"; do
  echo ">> $item"
done

