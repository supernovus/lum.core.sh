#< lum::core /var
# Variable related functions

lum::var -i LUM_NEED_ERRCODE =? 199

lum::fn lum::var::is
#$ <<varname>>
#
# Test if a variable IS set.
#
# A set variable is one with a non-empty value.
#
lum::var::is() {
  [ -n "${!1}" ]
}

lum::fn lum::var::declared
#$ <<varname>>
#
# Test if a global variable is declared.
#
# A declared variable is one that is known to Bash.
# May test for a global variable, or a local variable.
# 
lum::var::declared() {
  declare -p "$1" >/dev/null 2>&1
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

lum::fn lum::var::has
#$ <<varname>> <<want>>
#
# See if an array variable contains a value.
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

lum::fn lum::var::merge
#$ <<dest>> <<sources...>>
#
# Merge a bunch of associative arrays
#
# ((dest))      The name of the destination variable.
#           Must exist and be a ``-A`` type variable.
#
# ((sources))   For each source name listed, if there is a variable
#           with that name of type ``-A`` then we will copy any key/value
#           mappings out of it into the destination variable.
#
#           Latter sources with duplicate keys will overwrite earlier ones.
#
lum::var::merge() {
  [ $# -lt 2 ] && lum::help::usage
  [ "$(lum::var::type "$1")" != "-A" ] && lum::help::usage
  local -n mapDestVar="$1"
  shift

  local varKey

  while [ $# -gt 0 ]; do
    if [ -n "$1" -a "$(lum::var::type "$1")" = "-A" ]; then
      local -n mapSrcVar="$1"
      for varKey in "${!mapSrcVar[@]}"; do
        mapDestVar[$varKey]="${mapSrcVar[$varKey]}"
      done
    fi
    shift
  done
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
  local -i debugVal="${2:-0}"
  shift 2
  if [ $# -eq 0 ]; then
    debugVar="$debugVal"
  elif [ "$debugVar" -ge "$debugVal" ]; then 
    echo "$@"
  else
    return 1
  fi
  return 0
}
