## core lum::var

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
  [ $# -lt 2 ] lum::help::usage
  local -n echoVar="$1"
  local -i wantVal="$2"
  shift; shift;
  [ $echoVal -ge $wantVal ] && echo "$@"
}
