## use def

[ -z "$LUM_USE_ERRCODE" ] && LUM_USE_ERRCODE=222

declare -ga LUM_LIB_DIRS
declare -ga LUM_CONF_DIRS
declare -ga LUM_CONF_ALIASES
declare -gA LUM_USE_NAMES
declare -gA LUM_USE_FILES
declare -gA LUM_LIB_PREFIX_DIR

lum::fn lum::use
#$ <<arguments...>>
#
# Use one or more libraries and/or config files.
#
# Each argument is the name of an item you want to use,
# or one of the special options:
#
# ``--need``          Following items are mandatory.
# ``--opt``           Following items are optional.
# ``--conf``          Following items are config files.
# ``--lib``           Following items are library files.
#
# Default options are as if ``--need --lib`` was passed.
#
lum::use() {
  local libFile isFatal=1 useConf=0 cacheKey findFile prefix
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "--need" ]; then
      isFatal=1
    elif [ "$1" = "--opt" ]; then 
      isFatal=0
    elif [ "$1" = "--conf" ]; then
      useConf=1
    elif [ "$1" = "--lib" ]; then 
      useConf=0
    else
      cacheKey="$useConf:$1"
      #echo "use($cacheKey) = ${LUM_USE_NAMES[$cacheKey]}" >&2
      [ "${LUM_USE_NAMES[$cacheKey]}" = "1" ] && shift && continue
      if [ $useConf -eq 1 ]; then
        findFile="${1//::/\/}"
        libFile="$(lum::use::find $1.conf ${LUM_CONF_DIRS[@]})"
      else
        [ -n "${LUM_LIB_VER[$1]}" ] && shift && continue
        libFile="$(lum::use::findPrefixed $1.sh)"
        if [ $? -ne 0 ]; then
          libFile="$(lum::use::find ${1//::/\/}.sh ${LUM_LIB_DIRS[@]})"
        fi
      fi

      [ "${LUM_USE_FILES[$libFile]}" = "1" ] && shift && continue
      if [ -f "$libFile" ]; then 
        [ $useConf -eq 1 ] && lum::use::-conf "$libFile" || . "$libFile"
        LUM_USE_NAMES[$cacheKey]=1
        LUM_USE_FILES[$libFile]=1
      elif [ $isFatal -eq 1 ]; then
        echo "Could not find $1 library."
        exit $LUM_USE_ERRCODE
      fi
    fi
    shift
  done
}

lum::fn lum::use::-conf
#$ <<filename>>
#
# Internal method to load a config file
#
# Used by ``lum::use`` to load config files.
# Supports config-specific function aliases.
# Any alias in the ``LUM_CONF_ALIASES`` list will be
# made available for use in config files.
#
lum::use::-conf() {
  [ $# -eq 0 ] && lum::help::usage
  local conf="$1" A F
  for A in "${LUM_CONF_ALIASES[@]}"; do
    lum::fn::is "$A" && echo "function '$F' already exists" && exit $LUM_USE_ERRCODE 
    F="${LUM_ALIAS_FN[$A]}"
    [ -n "$F" ] && lum::fn::copy "$F" "$A" 
  done
  . "$conf"
  for A in "${LUM_CONF_ALIASES[@]}"; do
    unset "$A"
  done
}

lum::fn lum::use::find
#$ <<filename>> <<dirs...>>
# 
# Find a file in a list of possible directories.
# The first directory to contain the file wins.
#
# ((filename))   The filename we're looking for.
#
# ((dirs))       One or more directories to look for files in.
#
lum::use::find() {
  [ $# -lt 2 ] && lum::help::usage
  local tryfile AD AF="$1"
  shift
  #echo "looking for $AF in known paths" >&2
  for AD in "$@"; do
    [ ! -d "$AD" ] && continue
    tryfile="$AD/$AF"
    [ -f "$tryfile" ] && echo "$tryfile" && return 0
  done
  return 1
}

lum::fn lum::use::findPrefixed
#$ <<name>>
#
# Look for a file in our prefixed library paths.
# 
# For each of library prefixes registered, see if the
# requested name starts with the prefix, and if it does,
# replace the prefix with the associated directory and
# see if the file exists.
#
# ((name))   The filename we're looking for.
#
lum::use::findPrefixed() {
  [ $# -lt 1 ] && lum::help::usage
  local tryfile AD AF="$1" prefix
  #echo "looking for $AF via prefix" >&2
  for prefix in "${!LUM_LIB_PREFIX_DIR[@]}"; do
    #echo "checking '$prefix' prefix" >&2
    lum::str::startsWith "$AF $prefix" || continue
    AD="${LUM_LIB_PREFIX_DIR[$prefix]}"
    [ ! -d "$AD" ] && continue
    tryfile="${AF/$prefix/$AD\/}"
    tryfile="${tryfile//::/\/}"
    #echo "looking for filename '$tryfile'" >&2
    [ -f "$tryfile" ] && echo "$tryfile" && return 0
  done
  return 1
}

lum::fn lum::use::libdir
#$ <<directory>> [[libprefix]]
#
# Add a path containing libraries.
#
# ((directory))  The directory with the library files.
#
# ((libprefix))  If specified, libraries prefixed with the
#            name will use this directory by default.
#
lum::use::libdir() {
  [ $# -lt 1 ] && lum::help::usage
  LUM_LIB_DIRS+=("$1")
  [ -n "$2" ] && LUM_LIB_PREFIX_DIR[$2]="$1"
}

lum::fn lum::use::confdir
#$ <<directory>>
#
# Add a path containing configuration files.
#
# ((directory))  The directory with the config files.
#
lum::use::confdir() {
  [ $# -lt 1 ] && lum::help::usage
  LUM_CONF_DIRS+=("$1")
}


