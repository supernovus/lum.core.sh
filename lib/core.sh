#$< lum::core
# Core library

invalid_bash() {
  echo "Must use Bash version 4.4 or higher" >&2
  exit 150
}

[ -z "${BASH_VERSION}" ] && invalid_bash
[ "${BASH_VERSINFO[0]}" -lt 4 ] && invalid_bash
[ "${BASH_VERSINFO[0]}" -eq 4 -a "${BASH_VERSINFO[1]}" -lt 4 ] && invalid_bash

if [ -z "$LUM_CORE" ]; then
  declare -gr SCRIPTNAME="$(basename $0)"
  declare -gr LUM_CORE_LIB_DIR="$(dirname ${BASH_SOURCE[0]})"
  declare -gr LUM_CORE=1
  declare -gi LUM_CORE_REBOOT=0
elif [ -z "$LUM_CORE_LIB_DIR" ]; then
  echo "Invalid lum-core environment"
  exit 160
fi

# The bootstrap functions are needed before all else.
. "$LUM_CORE_LIB_DIR/core/bootstrap.sh"

# Load the rest of the core sub-modules.
lum::use::load-subs "$LUM_CORE_LIB_DIR/core/src"

## Add our module path.
lum::use::libdir "$LUM_CORE_LIB_DIR/modules" lum::
