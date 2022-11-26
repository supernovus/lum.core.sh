#!/bin/bash

LUM_CORE_BIN_DIR="$(realpath -e "$(dirname "$0")")"
LUM_CORE_PKG_DIR="$(dirname "$LUM_CORE_BIN_DIR")"

. $LUM_CORE_PKG_DIR/lib/core.sh

lum::use lum::themes::default lum::getopts lum::help::cli

lum::help::cli "$@"
