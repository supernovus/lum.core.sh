#@lib: lum::core /var
#@desc: Variable related functions

[ -z "$LUM_NEED_ERRCODE" ] && LUM_NEED_ERRCODE=199

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

lum::fn lum::var::not
#$ <<varname>>
#
# Test if a variable is NOT set.
#
# A set variable is one with a non-empty value.
#
lum::var::not() {
  [ -z "${!1}" ]
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

lum::fn lum::var::need
#$ <<varname>>
#
# If a variable is NOT set, die with an error.
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

lum::fn lum::var::sort
#$ <<invar>> <<outvar>> [[options...]]
#
# Sort an array
#
# ((invar))        The name of the array variable to sort.
# ((outvar))       The name of the target array variable.
# ((options))      Any options for the ``sort`` command.
#
lum::var::sort() {
  [ $# -lt 2 ] && lum::help::usage
  local -n invar="$1"
  local -n outvar="$2"
  shift 2
  local sortOpts="$@"
  local IFS=$'\n'
  outvar=($(sort $sortOpts <<<"${invar[*]}"))
}

lum::fn lum::var::mergeMaps
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
lum::var::mergeMaps() {
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

lum::fn lum::var::rmFrom
#$ [[options]] <<varname>> <<value...>>
#
# Remove value(s) from an array (-a) variable
# Does NOT work with associative array (-A) variables!
#
# ((varname))     The name of the array variable.
# ((value))       One or more values to be removed.
#
# ((options))     Named options for advanced features:
#
# ``-i``        Reindex the array (if you care about consecutive index keys).
# ``-r``        ((value)) is a RegExp to match rather than a single value.
#
lum::var::rm() {
  local -i reindex=0 isRE=0

  while [ $# -gt 0 ]; do
    case "$1" in 
      -i)
        reindex=1
        shift
      ;;
      -r)
        isRE=1
        shift
      ;;
      *)
        break
      ;;
    esac
  done

  [ $# -lt 2 ] && lum::help::usage

  [ "$(lum::var::type "$1")" != "-a" ] && lum::help::usage
  local findVal curVal curKey

  local -n theArray="$1"
  shift

  while [ $# -gt 0 ]; do
    findVal="$1"
    if [ $reindex -eq 1 ]; then
      local -a newArray=()
      for curVal in "${theArray[@]}"; do
        if [ $isRE -eq 1 ]; then
          [[ $curVal =~ $findVal ]] || newArray+=("$curVal")
        else
          [ "$curVal" = "$findVal" ] || newArray+=("$curVal")
        fi
      done
      theArray=("${newArray[@]}")
    else
      for curKey in "${!theArray[@]}"; do
        curVal="${theArray[$curKey]}"
        if [ $isRE -eq 1 ]; then
          [[ $curVal =~ $findVal ]] && unset "theArray[$curKey]"
        else
          [ "$curVal" = "$findVal" ] && unset "theArray[$curKey]"
        fi
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

lum::fn lum::var::id
#$ <<string>> [[case=0]]
#
# Make any string into a valid variable identifier
# 
# ((string))        The input string
#
# ((case))          How to handle identifier letter case.
#               `` 0`` = Case sensitive; don't change case at all.
#               `` 1`` = Force identifier to uppercase.
#               ``-1`` = Force identifier to lowercase.
#
lum::var::id() {
  local restore="$(shopt -p extglob)"
  shopt -s extglob
  local ident="${1//+([^[:word:]])/_}"
  ident="${ident%_}"
  $restore

  local -i csm="${2:-0}"
  case "$csm" in 
    1)
      ident="${ident^^}"
    ;;
    -1)
      ident="${ident,,}"
    ;;
  esac

  echo "$ident"
}
