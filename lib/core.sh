## Core functions for Lum.sh libraries

[ -z "$BASH_VERSION" ] && echo "Must use bash" && exit 150
[ "$BASH_VERSINFO" -lt 4 ] && echo "Bash version 4 or higher required." && exit 150
[ -z "${BASH_SOURCE[0]}" ] && echo "Must source init.sh" && exit 101
[ -z "$LUM_CORE_LIB_DIR" ] && LUM_CORE_LIB_DIR="$(dirname ${BASH_SOURCE[0]})"
[ -z "$LUM_USAGE_TITLE" ] && LUM_USAGE_TITLE="usage: "
[ -z "$LUM_USE_ERRCODE" ] && LUM_USE_ERRCODE=222
[ -z "$LUM_NEED_ERRCODE" ] && LUM_NEED_ERRCODE=199
[ -z "$LUM_USAGE_STACK" ] && LUM_USAGE_STACK=0

SCRIPTNAME="$(basename $0)"
declare -r LUM_USAGE_PREFIX="#$"
declare -r LUM_HELP_END_MARKER="#:"

LUM_CORE=1.0.0

declare -ga LUM_LIB_DIRS
declare -ga LUM_CONF_DIRS

declare -gA LUM_USE_NAMES
declare -gA LUM_USE_FILES

declare -gA LUM_LIB_PREFIX_DIR
declare -gA LUM_LIB_FILES
declare -gA LUM_LIB_VER
declare -gA LUM_FILE_LIBS

declare -gA LUM_FN_FILES
declare -gA LUM_FN_ALIAS
declare -gA LUM_FN_FLAGS
declare -gA LUM_FN_HELP_TAGS
declare -gA LUM_ALIAS_FN

declare -gA LUM_THEME

#echo "<core.sh> BASH_SOURCE=${BASH_SOURCE[@]}" >&2

#$ lum::fn <<name>> [[flags=0]] `{...}`
#
# Register a library function (or help topic).
#
# ((name))       The fully qualified name (e.g. ``lum::test``).
#            In the case of a real function, this must be the actual
#            function name as defined in the file, not an alias.
#            For non-function help topics, this can be anything.
#
# ((flags))      Bitwise flags that modify the definition.
#            See ``lum::fn.flags`` for details.
# 
# Any arguments beyond the above are special named options.
# See ``lum::fn.named`` for details.
#
lum::fn() {
  [ $# -lt 1 ] && lum::help::usage
  local caller="${BASH_SOURCE[1]}" fName="$1" fOpts="${2:-0}" 
  LUM_FN_FILES[$fName]="$caller"
  LUM_FN_FLAGS[$fName]="$fOpts"
  if [ $# -gt 2 ]; then
    shift; shift;
    while [ $# -gt 0 ]; do
      case "$1" in 
        -a)
          lum::fn::alias "$fName" "$2" "$3" "$4"
          shift; shift; shift; shift;
        ;;
        -t)
          lum::fn::helpTags "$fName" "$2" "$3"
          shift; shift; shift;
        ;;
        *)
          echo "unrecognized lum::fn argument '$1'" >&2
          lum::help::diag 2
          shift
        ;;
      esac
    done
  fi
}
lum::fn lum::fn 1

lum::fn lum::fn.flags 2
#$ `{int}`
#
# Bitwise flags modifying function/help behaviour.
#
# ``1``    The help text must start with an extended usage line,
#        including the officially registered function name.
#        If not set, the help text starts at the line below the 
#        ``lum::fn`` call registering the function.
# ``2``    The help text must end with a `{#: funcname}` line.
#        Useful for documenting topics without an actual function.
#        If not set, the help text ends at the function declaration.
#
#: lum::fn.flags

lum::fn lum::fn.named 2
#$ `{*}`
#
# Named options for the ``lum::fn`` function.
#
# Each of these has a specific number of arguments that MUST be passed.
# You can specify as many options as you like, as long as the argument
# count is correct. Below we'll list the mandatory argument count, and
# the target function that will be called with the arguments. The ``F``
# symbol refers to the ((funcname)) parameter.
#
# ((-a))   `{(3)}` → ``lum::fn::alias F ...``
# ((-t))   `{(2)}` → ``lum::fn::helpTags F ...``
#
#: lum::fn.named

lum::fn lum::fn::alias 
#$ <<funcname>> <<alias>> [[opts=0]] [[list=0]]
#
# Create a function alias.
#
# This is primarily only used by the help system, but
# will also be used for command line dispatch as well.
#
# ((funcname))   The full function name (e.g. ``myapp::coolFunc``).
#
# ((alias))      The alias name (e.g. ``--cool``).
#
# ((opts))       Options as bitwise flags.
#            ``1`` = This is the primary name shown in the help/usage text.
#
# ((list))       The name of a command list to add the alias to.
#            It must be a valid global variable name, and it must be
#            declared as a flat array (``-a``) variable.
#            If set as ``0`` this is skipped.
#
lum::fn::alias() {
  [ $# -lt 2 ] && lum::help::usage
  local fName="$1" aName="$2" opts="${3:-0}" listname="${4:-0}"
  LUM_ALIAS_FN[$aName]="$fName"
  lum::flag::is $opts 1 && LUM_FN_ALIAS[$fName]="$aName"
  if [ -n "$listname" -a "$listname" != "0" ]; then 
    local -n list="$listname"
    list+=($aName)
  fi
}

lum::fn lum::fn::helpTags
#$ <<funcname>> <<mode>> <<tags>>
#
# Set help template tags for a function/topic.
#
# ((funcname))   `{[str]}` The full function or topic name.
#             A value of ``*`` is special, being fallback values
#             for functions without their own settings.
#
# ((mode))       `{[int]}` The help mode this applies to.
#             See ``lum::help`` for a list of modes.
#
# ((tags))       `{[int]}` The template tags allowed in this mode.
#             See ``lum::help::tmpl`` for a list of tags.
#
# The last two parameters may be specified multiple times, always
# in matching pairs.
# 
lum::fn::helpTags() {
  [ $# -lt 3 ] && lum::help::usage 
  local name="$1" key
  shift
  while [ $# -gt 0 ]; do
    key="$1|$name"
    LUM_FN_HELP_TAGS[$key]="$2"
    shift; shift;
  done
}

lum::fn::helpTags '*' 0 5 1 3 2 5

lum::fn lum::fn::run 0 -t 0 7
#$ <<mode>> `{modeArgs...}` <<name>> `{funcArgs...}`
#
# Call a function and pass it all other parameters.
#
# ((mode))  Determine which functions can be called.
#       ``0`` = No restrictions (dangerous!)
#             No additional arguments.
#       ``1`` = Defined aliases only.
#             No additional arguments.
#       ``2`` = Only names in a specified list.
#             <<listname>>  The list of names.
#             
# ((name))  The function name or an alias to the function.
#
lum::fn::run() {
  [ $# -lt 2 ] && lum::help::usage
  local mode="$1" fname aname cmd
  shift;

  if [ "$mode" = "2" ]; then
    [ $# -lt 2 ] && lum::help::usage
    lum::var::has "$1" "$2" || lum::fn::run-err "$2"
    fname="$2"
    shift; shift;
  else
    fname="$1"
    shift;
  fi

  aname="${LUM_ALIAS_FN[$fname]}"

  case "$mode" in 
    0|2)
      [ -n "$aname" ] && cmd="$aname" || cmd="$fname"
    ;;
    1)
      [ -n "$aname" ] && cmd="$aname" || lum::fn::run-err "$fname"
    ;;
  esac

  if lum::fn::is "$cmd"; then
    "$cmd" "$@"
  else 
    lum::fn::run-err "$fname"
  fi
}

## Private sub-function for lum::fn::run
lum::fn::run-err() {
  local err="${LUM_THEME[error]}" end="${LUM_THEME[end]}"
  echo "Unrecognized command '$err$1$end' specified" >&2
  exit 1
}

lum::fn lum::help
#$ <<name>> [[mode=0]]
#
# Show help information for a function.
#
# ((name))      Name of the function (e.g. ``lum::help``)
#
# ((mode))      What help text we want to return:
#           ``0`` = Return the entire help text.
#           ``1`` = Return only the usage line.
#           ``2`` = Return only the summary line.
#
lum::help() {
  [ $# -lt 1 ] && lum::help::usage
  local prefind suffind dName fName="$1" want=${2:-0} S E output
  local err="${LUM_THEME[error]}"
  local end="${LUM_THEME[end]}"

  [ -n "${LUM_ALIAS_FN[$fName]}" ] && fName="${LUM_ALIAS_FN[$fName]}"
  
  local flags="${LUM_FN_FLAGS[$fName]:-0}" 
  local usageTags _tk="$want|$fName" _ak="$want|*"
  local wantTags="${LUM_FN_HELP_TAGS[$_tk]:-${LUM_FN_HELP_TAGS[$_ak]}}"

  if [ "$want" = 1 ]; then 
    usageTags="$wantTags" 
  else 
    _tk="1|$fName"
    _ak="1|*"
    usageTags="${LUM_FN_HELP_TAGS[$_tk]:-${LUM_FN_HELP_TAGS[$_ak]}}"
  fi

  if lum::flag::is $flags 1; then
    prefind="${LUM_USAGE_PREFIX} $fName"
  else
    prefind="lum::fn $fName"
  fi

  if [ -n "${LUM_FN_ALIAS[$fName]}" ]; then
    dName="${LUM_FN_ALIAS[$fName]} "
  elif lum::flag::not $flags 1; then
    dName="$fName "
  fi

  LFILE="${LUM_FN_FILES[$fName]}"

  if [ -z "$LFILE" -o ! -f "$LFILE" ]; then
    echo "function '$err$fName$end' not recognized" >&2
    return 1
  fi

  #echo "<help> fName='$fName' LFILE='$LFILE'"

  S=$(grep -nm 1 "^$prefind" "$LFILE" | cut -d: -f1)

  if [ -z "$S" ]; then
    echo "no help definition found for '$err$fName$end'" >&2
    return 2
  fi

  lum::flag::not $flags 1 && ((S++))

  if [ "$want" = 2 ]; then
    ((S+=2))
    sed -n "${S}{s/^#//;p}" "$LFILE" | lum::help::tmpl 5
    return 0
  fi

  if [ "$want" = 0 ]; then
    if lum::flag::is $flags 2; then 
      suffind="${LUM_HELP_END_MARKER} $fName"
    else 
      suffind="${fName}()"
    fi
    E=$(grep -nm 1 "^$suffind" "$LFILE" | cut -d: -f1)
    if [ -z "$E" ]; then
      echo "no function definition found for '$err$fName$end'" >&2
      return 3
    fi
  fi

  #echo "<help> S='$S',E='$E'"
  #echo -n "$dName"
  sed -n "${S}{s/$LUM_USAGE_PREFIX\s*/$dName/;p}" "$LFILE" | lum::help::tmpl $usageTags
  [ "$want" = 1 ] && return 0

  ((S++))
  ((E--))
  #echo "<help> S='$S',E='$E'"
  sed -n "${S},${E}{s/^#//;p}" "$LFILE" | lum::help::tmpl $wantTags
  return 0
}

lum::fn lum::help::diag
#$ [[level=1]]
#
# Get a stack trace.
#
# ((level))  Starting position in trace.
#            
lum::help::diag() {
  local S=${1:-1} E=${#BASH_SOURCE[@]} L
  local mc="${LUM_THEME[diag.func]}"
  local fc="${LUM_THEME[diag.file]}"
  local ec="${LUM_THEME[end]}"
  ((E--))
  #echo ">> BASH_SOURCE=${BASH_SOURCE[@]}" >&2
  #echo ">> FUNCNAME=${FUNCNAME[@]}" >&2
  for L in $(seq $S $E);
  do
    echo " → $mc${FUNCNAME[$L]}$ec ($fc${BASH_SOURCE[$L]}$ec)"
  done
}

lum::fn lum::help::usage
#$ [[funcname]] [[errcode=100]]
#
# Show usage summary for a function.
#
# ((funcname))  Name of the function (e.g. ``lum::help::usage``)
#           If not specified, or set to ``0``, we use the name of the 
#           calling function.
#
# ((errcode))   Error code to return when exiting script.
#           If set to ``-1`` then exit won't be called.
#
lum::help::usage() {
  local fName want errCode DL

  if [ -z "$1" -o "$1" = "0" ]; then
    fName="${FUNCNAME[1]}"
    DL=2
  else
    fName="$1"
    DL=1
  fi

  errCode=${2:-100}
  want="$(lum::help $fName 1)"
  if [ -n "$want" ]; then
    [ "$LUM_USAGE_TITLE" != "0" ] && want="${LUM_USAGE_TITLE}$want"
    echo "$want" >&2
    if [ "$LUM_USAGE_STACK" != "0" ]; then 
      lum::help::diag $DL >&2
    fi
  fi
  [ $errCode -ne -1 ] && exit $errCode
}

lum::fn lum::help::tmpl
#$ <<tags>>
#
# Parse ``STDIN`` for help document tags.
#
# If a theme is loaded, and the terminal supports it,
# the help text will have fancy colours to make it easier
# to read.
#
# ((tags))  Bitwise flags for what tags to allow.
#       ``1``  = Syntax `{`\\{ }\\`}` and pad `{@\\int()}` tags.
#       ``2``  = Arguments `{<\\< >\\>}` and options `{[\\[ ]\\]}` tags.
#       ``4``  = Parameter `{(\\( )\\)}` and value `{`\\` `\\`}` tags.
#       ``8``  = Extension tags: `{@\\>pipeCmd}`, `{@\\<passCmd}`
#
lum::help::tmpl() {
  local tags="${1:-0}"
  local SYN=1 ARG=2 VAL=4 EXT=8

  local argPattern='(.*?)<<(\w+)(\.\.\.)?>>(.*)'
  local optPattern='(.*?)\[\[(\w+)(=)?(\w+)?(\.\.\.)?\]\](.*)'
  local parPattern='(.*?)\(\((.*?)\)\)(.*?)'
  local synPattern='(.*?)`\{(.*?)\}`(.*)'
  local valPattern='(.*?)``(.*?)``(.*)'
  local extPattern='(.*?)@([<>])(\S+?);(.*)'
  local padPattern='(.*?)@(\d+)\((.*?)\)(.*)'
  local escPattern='(.*?)\\\\(.*)'

  local text="$(cat -)" before after arg eq def param rep

  local bc="${LUM_THEME[help.syntax]}"
  local ac="${LUM_THEME[help.arg]}"
  local oc="${LUM_THEME[help.opt]}"
  local dc="${LUM_THEME[help.def]}"
  local pc="${LUM_THEME[help.param]}"
  local vc="${LUM_THEME[help.value]}"
  local er="${LUM_THEME[error]}"
  local ec="${LUM_THEME[end]}"

  if lum::flag::is $tags $EXT; then
    while [[ $text =~ $extPattern ]]; do 
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[4]}"
      arg="${BASH_REMATCH[3]}"
      eq="${BASH_REMATCH[2]}"
      text="$before$after"
      if lum::fn::is "$arg"; then
        if [ "$eq" = ">" ]; then
          text="$(echo "$text" | $arg $tags)"
        elif [ "$eq" = "<" ]; then
          text="$($arg $tags "$text")"
        fi
      fi
    done
  fi

  if lum::flag::is $tags $ARG; then
    while [[ $text =~ $argPattern ]]; do 
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[4]}"
      arg="${BASH_REMATCH[2]}"
      rep="${BASH_REMATCH[3]}"
      param="$bc<$ac$arg$bc"
      [ -n "$rep" ] && param="$param$rep"
      param="$param>$ec"
      text="$before$param$after"
    done

    while [[ $text =~ $optPattern ]]; do 
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[6]}"
      arg="${BASH_REMATCH[2]}"
      eq="${BASH_REMATCH[3]}"
      def="${BASH_REMATCH[4]}"
      rep="${BASH_REMATCH[5]}"
      param="$bc[$oc$arg$bc"
      [ "$eq" = "=" -a -n "$def" ] && param="$param$eq$dc$def$bc"
      [ -n "$rep" ] && param="$param$rep"
      param="$param]$ec"
      text="$before$param$after"
    done
  fi

  if lum::flag::is $tags $VAL; then
    while [[ $text =~ $parPattern ]]; do 
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[3]}"
      arg="${BASH_REMATCH[2]}"
      param="$pc$arg$ec"
      text="$before$param$after"
    done

    while [[ $text =~ $valPattern ]]; do 
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[3]}"
      arg="${BASH_REMATCH[2]}"
      param="'$vc$arg$ec'"
      text="$before$param$after"
    done
  fi

  if lum::flag::is $tags $SYN; then
    while [[ $text =~ $synPattern ]]; do 
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[3]}"
      arg="${BASH_REMATCH[2]}"
      param="$bc$arg$ec"
      text="$before$param$after"
    done

    while [[ $text =~ $padPattern ]]; do
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[4]}"
      rep="${BASH_REMATCH[2]}"
      arg="${BASH_REMATCH[3]}"
      param="$(lum::str::pad $rep "$arg")"
      text="$before$param$after"
    done

    while [[ $text =~ $escPattern ]]; do
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[2]}"
      text="$before$after"
    done
  fi

  echo "$text"
}

lum::fn lum::help::list 
#$ <list> [pad=20] [sep] [prefix] [suffix]
#
# Print a list of commands from a list (array variable).
#
# ((list))      The name of the list variable.
# 
# ((pad))       The character length for the commands column.
#           Most terminals are ``80`` characters in total.
#           So the command column and description column should not
#           exceed that.
#
# ((sep))       A separator between columns (e.g. ``"-"``)
#
# ((prefix))    Prefix for command columns (e.g. ``" '"``)
#
# ((suffix))    Suffix for command columns (e.g. ``"'"``)
#
lum::help::list() {
  [ $# -lt 1 ] && lum::help::usage

  local pad="${2:-20}" sep="$3" pf="$4" sf="$5" C K U
  local -n list="$1"
  local ic="${LUM_THEME[help.list.item]}"
  local sc="${LUM_THEME[help.syntax]}"
  local ec="${LUM_THEME[end]}"

  for K in "${list[@]}"; do
    C="$(lum::str::pad $pad "$pf$K$sf")"
    U="$(lum::help $K 2)"
    echo "$ic$C$sc$sep$ec$U"
  done
}

lum::fn lum::lib
#$ <<libname>> <<version>>
#
# Register an extension library.
#
lum::lib()
{
  [ $# -lt 2 ] && lum::help::usage
  local caller="${BASH_SOURCE[1]}" name="$1" ver="$2"
 
  if [ -n "${LUM_LIB_VER[$name]}" ]; then
    echo "library '$name' already registered"
    return 1
  fi

  LUM_LIB_VER[$name]=$ver
  LUM_LIB_FILES[$name]="$caller"
  LUM_FILE_LIBS[$caller]="$name"
}

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
      [ "${LUM_USE_NAMES[$cacheKey]}" = "1" ] && continue
      if [ $useConf -eq 1 ]; then
        findFile="${1//::/\/}"
        libFile="$(lum::use::find $1.conf ${LUM_CONF_DIRS[@]})"
      else
        [ -n "${LUM_LIB_VER[$1]}" ] && continue
        libFile="$(lum::use::findPrefixed $1.sh)"
        if [ $? -ne 0 ]; then
          libFile="$(lum::use::find ${1//::/\/}.sh ${LUM_LIB_DIRS[@]})"
        fi
      fi

      [ "${LUM_USE_FILES[$libFile]}" = "1" ] && continue
      if [ -f "$libFile" ]; then 
        . "$libFile"
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

lum::use::libdir $LUM_CORE_LIB_DIR lum::

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

lum::fn lum::use::from
#$ <<path>>
#
# Look for special files indicating which libraries to load.
#
# ((path))      The path to the control files.
#
# Two types of control files are supported:
#
# ``.lib``    The basename of these files are the names of the libraries.
# ``.cnf``    The basename of these files are the name sof the config files.
#
lum::use::from() {
  [ $# -lt 1 ] && lum::help::usage
  local libName
  if [ -d "$1" ]; then
    for libName in $1/*.lib; do
      [ -e "$libName" ] || continue
      libName=$(basename $libName .lib)
      lum::use $libName
    done

    for libName in $1/*.cnf; do
      [ -e "$libName" ] || continue
      libName=$(basename $libName .cnf)
      lum::use --opt --conf $libName
    done
  fi
}

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

lum::fn lum::fn::copy
#$ <<oldName>> <<newName>>
#
# Makes a copy of a function.
#
# ((oldName))  The existing function.
# ((newName))  The name for the copy.
#
# Useful for making a backup of an existing function
# before overriding it with a new version.
#
lum::fn::copy() {
  [ $# -ne 2 ] && lum::help::usage
  test -n "$(declare -f "$1")" || return 
  eval "${_/$1/$2}"
}

lum::fn lum::fn::list
#$ [[prefix]]
#
# Show a list of functions.
#
# ((prefix))  Show only functions starting with this.
#
lum::fn::list() {
  compgen -A function "$1"
}

lum::fn lum::fn::is
#$ <<name>>
#
# Test if a function exists
#
lum::fn::is() {
  declare -F "$1" >/dev/null
}

lum::fn lum::str::pad
#$ <<len>> <<string...>>
#
# Pad a string to a specified length.
#
# ((len))     The length the final string should be.
#
# ((string))  One or more strings to concat.
#
lum::str::pad() {
  [ $# -lt 2 ] && lum::help::usage
  local len=$1
  shift
  printf "%-${len}s" "$@"
}

lum::fn lum::str::startsWith
#$ <<string>> <<prefix>>
#
# Test for a prefix in a string.
#
lum::str::startsWith() {
  case "$1" in 
    "$2"*) return 0 ;;
    *) return 1 ;;
  esac
}

lum::fn lum::str::endsWith
#$ <<string>> <<suffix>>
#
# Test for a suffix in a string.
#
lum::str::endsWith() {
  case "$1" in 
    *"$2") return 0 ;;
    *) return 1 ;;
  esac
}

lum::fn lum::str::contains
#$ <<string>> <<substr>>
#
# Test for a sub-string in a string.
#
lum::str::contains() {
  case "$1" in 
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}

lum::fn lum::args::has 
#$ <<want>> <<values...>>
#
# See if a list of arguments contains a value.
#
lum::args::has() {
  [ $# -lt 2 ] && lum::help::usage
  local item want="$1"
  shift 
  for item; do
    [[ "$item" == "$want" ]] && return 0
  done
  return 1
}

lum::fn lum::flag::is
#$ <<bitvalue1>> <<bitvalue2>>
#
# Test for the presense of bitwise flags.
#
# Performs a bitwise AND against two values.
# Returns true if the value is NOT zero.
#
lum::flag::is() {
  [ $# -ne 2 ] && lum::help::usage
  local bitA=$1 bitB=$2 testVal
  testVal=$((bitA & bitB))
  [ $testVal -eq 0 ] && return 1
  return 0
}

lum::fn lum::flag::not
#$ <<bitvalue1>> <<bitvalue2>>
#
# Test for the absense of bitwise flags.
#
# Performs a bitwise AND against two values.
# Returns true if the value IS zero.
#
lum::flag::not() {
  [ $# -ne 2 ] && lum::help::usage
  local bitA=$1 bitB=$2 testVal
  testVal=$((bitA & bitB))
  [ $testVal -eq 0 ] && return 0
  return 1
}

lum::fn lum::flag::set
#$ <<bitvalues...>>
#
# Combine all arguments with a bitwise OR.
#
lum::flag::set() {
  [ $# -lt 1 ] && lum::help::usage
  local retval=0 testval
  while [ $# -gt 0 ]; do
    testval=$1
    shift
    ((retval |= testval))
  done
  echo $retval
}

lum::lib lum::core $LUM_CORE
