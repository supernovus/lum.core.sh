## lum::core bootstrap file

[ -z "$BASH_VERSION" ] && echo "Must use bash" && exit 150
[ "$BASH_VERSINFO" -lt 4 ] && echo "Bash version 4 or higher required" && exit 150

declare -gr SCRIPTNAME="$(basename $0)"                # Name of the script.
declare -gr LUM_LIB_DIR="$(dirname ${BASH_SOURCE[0]})" # Core libs are here.
declare -gr LUM_CORE=1.0.0                             # Core version.

# The directory the core source files are in.
LUM_LIBS="$LUM_LIB_DIR/core"

# The function definition functions are needed before all else.
. "$LUM_LIBS/fn.sh"

# Now load the rest of the core source files.
for LUM_FILE in "$LUM_LIBS/src/"*.sh; do
  . "$LUM_FILE"
done

# Run the setup commands.
. "$LUM_LIBS/setup.sh"

# Clean up temporary stuff
unset LUM_LIBS LUM_FILE 

# Register the core library.
lum::lib lum::core $LUM_CORE

