#$< lum::core /use
# Library module loading system

lum::var -P LUM_ \
  -a LIB_DIRS CONF_DIRS CONF_ALIASES \
  -A USE_NAMES USE_FILES LIB_PREFIX_DIR \
  -i USE_ERRCODE =? 222

lum::fn::alias::group CONF 0 LUM_CONF_ALIASES

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
# ``--once``          Following items should only be loaded once.
# ``--reload``        Following items should be loaded every time.
#
# Default options are as if ``--need --lib --once`` was passed.
#
lum::use() {
  local libFile isFatal=1 useConf=0 reload=0 cacheKey prefix
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --need)
        isFatal=1
      ;;
      --opt) 
        isFatal=0
      ;;
      --conf)
        useConf=1
      ;;
      --lib) 
        useConf=0
      ;;
      --reload)
        reload=1
      ;;
      --once)
        reload=0
      ;;
      *)
        cacheKey="$useConf:$1"
        #echo "use($cacheKey) = ${LUM_USE_NAMES[$cacheKey]}" >&2
        if [ "$reload" = "0" -a "${LUM_USE_NAMES[$cacheKey]}" = "1" ]; then 
          shift
          continue
        fi

        if [ $useConf -eq 1 ]; then
          libFile="$(lum::use::find "${1//::/\/}.conf" "${LUM_CONF_DIRS[@]}")"
        else
          libFile="$(lum::use::findPrefixed $1.sh)"
          if [ $? -ne 0 ]; then
            libFile="$(lum::use::find "${1//::/\/}.sh" "${LUM_LIB_DIRS[@]}")"
          fi
        fi

        if [ -n "$libFile" -a -f "$libFile" ]; then 
          if [ "$reload" = "0" -a "${LUM_USE_FILES[$libFile]}" = "1" ]; then
            shift
            continue
          fi
          [ $useConf -eq 1 ] && lum::use::-conf "$libFile" || . "$libFile"
          LUM_USE_NAMES[$cacheKey]=1
          LUM_USE_FILES[$libFile]=1
        elif [ $isFatal -eq 1 ]; then
          lum::err "Could not find $1 library." $LUM_USE_ERRCODE
        fi
      ;;
    esac
    shift
  done
}

#$ lum::use,conf - <<filename>>
#
# Internal method to load a config file
#
# Used by ``lum::use`` to load config files.
# Supports config-specific function aliases.
# Any alias in the ``LUM_CONF_ALIASES`` list will be
# made available for use in config files.
#
#: lum::use,conf
lum::use::-conf() {
  [ $# -eq 0 ] && lum::help::usage lum::use,conf
  local conf="$1" A F
  for A in "${LUM_CONF_ALIASES[@]}"; do
    lum::fn::is "$A" && lum::warn "function '$F' already exists" && return $LUM_USE_ERRCODE 
    F="${LUM_ALIAS_FN[$A]}"
    [ -n "$F" ] && lum::fn::copy "$F" "$A" 
  done
  . "$conf"
  for A in "${LUM_CONF_ALIASES[@]}"; do
    unset -f "$A"
  done
  return 0
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
#$ <<name>> [[list=LUM_LIB_PREFIX_DIR]]
#
# Look for a file in one of our prefixed paths.
# 
# For each of library prefixes registered, see if the
# requested name starts with the prefix, and if it does,
# replace the prefix with the associated directory and
# see if the file exists.
#
# ((name))   The filename we're looking for.
# ((list))   Name of a ``-A`` map of prefix => path.
#
lum::use::findPrefixed() {
  [ $# -lt 1 ] && lum::help::usage
  local tryfile AD AF="$1" prefix
  local -n AL="${2:-LUM_LIB_PREFIX_DIR}"
  #echo "looking for $AF via prefix" >&2
  for prefix in "${!AL[@]}"; do
    #echo "checking '$prefix' prefix" >&2
    lum::str::startsWith "$AF" "$prefix" || continue
    AD="${AL[$prefix]}"
    [ ! -d "$AD" ] && continue
    tryfile="${AF/$prefix/$AD\/}"
    tryfile="${tryfile//::/\/}"
    #echo "looking for filename '$tryfile'" >&2
    [ -f "$tryfile" ] && echo "$tryfile" && return 0
  done
  return 1
}

lum::fn lum::use::libdir
#$ <<directory>> [[prefix]]
#
# Add a path containing libraries.
#
# ((directory))  The directory with the library files.
#
# ((prefix))     If specified, libraries prefixed with this
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
