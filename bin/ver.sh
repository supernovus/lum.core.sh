#!/bin/bash

LUM_CORE_BIN_DIR="$(dirname $0)"

. $LUM_CORE_BIN_DIR/../lib/core.sh

lum::use lum::themes::default lum::semver

lum::fn bin-test-ver 2 -h 0 more
#$ <<command>> `{...}`
#
# Semantic version test commands:
#
#  ``parse <<ver>>``        → Parse a version and show the structure.
#  ``comp <<v1>> <<v2>>``     → Compare two versions.
#
#: bin-test-ver

usage() {
  echo -n "usage: "
  lum::help bin-test-ver
  exit 1
}

parse_ver() {
  [ $# -lt 1 ] && usage
  local ver="$1" 
  local -i raw="${2:-0}"
  local -a VERS VK VV
  lum::semver::parse "$ver" VERS "$raw"
  for VK in "${!VERS[@]}"; do
    VV="${VERS[$VK]}"
    echo "[$VK]='$VV'"
  done
}

comp_vers() {
  [ $# -lt 2 ] && usage
  lum::semver::compare "$@"
} 

CMD="$1"
shift

case "$CMD" in 
  parse)
    parse_ver "$@"
  ;;
  comp)
    comp_vers "$@"
  ;;
  *)
    usage
  ;;
esac
