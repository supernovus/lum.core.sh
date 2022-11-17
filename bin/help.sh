#!/bin/bash

LUM_CORE_BIN_DIR="$(dirname $0)"

. $LUM_CORE_BIN_DIR/../lib/core.sh

lum::use lum::themes::default

lum::help "$@"

