#@lib: lum::core /var
#@desc: Global variable related functions

[ -z "$LUM_NEED_ERRCODE" ] && LUM_NEED_ERRCODE=199

lum::fn lum::var::is
#$ <<varname>>
#
# Test if a global variable IS set.
#
lum::var::is() {
  [ -n "${!1}" ]
}

lum::fn lum::var::not
#$ <<varname>>
#
# Test if a global variable is NOT set.
#
lum::var::not() {
  [ -z "${!1}" ]
}

lum::fn lum::var::type
#$ <<varname>>
#
# Echo the type value to ``STDOUT``.
#
# ``--``    A regular variable.
# ``-i``    An integer variable.
# ``-a``    An array variable.
# ``-A``    An associative array variable.
# ``-n``    A link to another variable.
# 
# Any other types supported by ``declare`` may be returned.
# If the variable has not been declared, the output will be empty.
#
lum::var::type() {
  [ $# -eq 0 ] && lum::help::usage
  declare -p "$1" 2>/dev/null | cut -d' ' -f2
}

lum::fn lum::var::need
#$ <<varname>>
#
# If a global variable is NOT set, die with an error.
#
lum::var::need() {
  if lum::var::not "$1"; then 
    echo "Missing '$1' variable" >&2
    exit $LUM_NEED_ERRCODE
  fi
}

lum::fn lum::var::has
#$ <<varname>> <<want>>
#
# See if a global array variable contains a value.
#
# ((varname))    The name of the global array variable.
#
# ((want))       The value we are looking for.
#
lum::var::has() {
  [ $# -lt 2 ] && lum::help::usage
  local item want="$2"
  local -n array="$1"
  for item in "${array[@]}"; do
    [[ "$item" == "$want" ]] && return 0
  done
  return 1
}

lum::fn lum::var::debug
#$ <<varname>> <<minval>> [[message...]]
#
# Debugging based on global variables.
#
# This is used to both set the debugging value, and
# to display messages if the value of the variable is >=
# the specified minimum value.
#
# Creating app-specific functions that supply the variable name
# is highly recommended to make this the most useful.
#
# ((varname))     The name of the global integer variable.
#
# ((minval))      The minimum integer value to display the message.
#
# ((message))     If used, the message to show if ``$varname >= $minval``;
#                 If not specified, then we set ``varname=$minval``;
#
lum::var::debug() {
  [ $# -lt 2 ] && lum::help::usage
  local -n debugVar="$1"
  local -i debugVal="$2"
  shift 2
  if [ $# -eq 0 ]; then
    debugVar="$debugVal"
  elif [ "$debugVar" -ge $debugVal ]; then 
    echo "$@"
  else
    return 1
  fi
  return 0
}
