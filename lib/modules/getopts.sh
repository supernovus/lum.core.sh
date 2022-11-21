#@lib: lum::getopts
#@desc: A wrapper around getopts

[ -z "$LUM_GETOPTS_ERR_INVALID_TYPE" ] && LUM_GETOPTS_ERR_INVALID_TYPE=170
[ -z "$LUM_GETOPTS_ERR_INVALID_FLAG" ] && LUM_GETOPTS_ERR_INVALID_FLAG=171
[ -z "$LUM_GETOPTS_ERR_MISSING_VAL"  ] && LUM_GETOPTS_ERR_MISSING_VAL=172
[ -z "$LUM_GETOPTS_ERR_FLAG_EXISTS"  ] && LUM_GETOPTS_ERR_FLAG_EXISTS=173
[ -z "$LUM_GETOPTS_ERR_NAME_EXISTS"  ] && LUM_GETOPTS_ERR_NAME_EXISTS=174
[ -z "$LUM_GETOPTS_ERR_INVALID_NAME" ] && LUM_GETOPTS_ERR_INVALID_NAME=175

lum::fn lum::getopts
#$ <<id>> [[prefix]]
#
# Create a set of functions for parsing arguments with getopts.
#
# ((id))              A unique id; must be valid in bash variables.
#
# ((prefix))          The prefix for the functions.
#                 Must be characters valid in bash functions.
#                 The default if not specified is: ``${id}::``.
#
# This calls ``lum::getopts::init (($id))``, and then generates some
# dynamically named functions that call the various ``lum::getopts::*`` 
# functions, automatically supplying the ((id)) argument.
#
# ``((${prefix}))def``    → ``lum::getopts::def``
# ``((${prefix}))parse``  → ``lum::getopts::parse``
#
# It also generates a couple functions that return the name of certain
# variables for getting the parsed results.
#
# ``((${prefix}))opts``    → ``echo "${id}_OPTS"``
# ``((${prefix}))args``    → ``echo "${id}_ARGS"``
# ``((${prefix}))lists``   → ``echo "${id}_LIST"``
#
lum::getopts() {
  [ $# -lt 1 ] && lum::help::usage
  local id=$1 prefix=${2:-"${1}::"}

  lum::getopts::init $id
  declare -g "${id}_PREF"="$prefix"

  lum::getopts::-wrap $prefix $id def
  lum::getopts::-wrap $prefix $id parse
  lum::getopts::-var $prefix $id OPTS opts
  lum::getopts::-var $prefix $id ARGS args
  lum::getopts::-var $prefix $id LIST lists
}

lum::getopts::-wrap() {
  local prefix="$1" id="$2" sub="$3"
  local create="${prefix}${sub}" target="lum::getopts::$sub"
  lum::fn::make "$create" "$target" $id \"\$@\"
}

lum::getopts::-var() {
  local prefix="$1" id="$2" var="$3" func="$4"
  local create="${prefix}${func}" target="${id}_${var}"
  lum::fn::make "$create" echo \"$target\"
}

lum::fn lum::getopts::init
#$ <<id>>
#
# Create a new set of getopts argument parsing rules.
#
# ((id))    A unique id. Must be a valid variable identifier.
#
# We will create several global variables for storing values:
# 
# `{[-A]}` ``${id}_NAME``           A map of ((flag)) to ((name)).
# `{[-A]}` ``${id}_FLAG``           A map of ((name)) to ((flag)).
# `{[-A]}` ``${id}_TYPE``           A map of ((flag)) to ((type)).
# `{[-a]}` ``${id}_LIST``           A map of ((name)) to ((var)), for lists. 
# `{[-A]}` ``${id}_OPTS``           Parsed named options.
# `{[-a]}` ``${id}_ARGS``           Parsed positional arguments.
# `{[--]}` ``${id}_GOPT``           A getopts format string.
#
# The ``lum::getopts::def`` function may also create more variables:
#
# `{[-a]}` ``${id}_${name}_VALS``   One for each list (``+``) flag.
#
# If ``lum::getopts`` was used, one extra variable is added:
#
# `{[--]}` ``${id}_PREF``           Function name prefix used.
#
lum::getopts::init() {
  [ $# -eq 0 ] && lum::help::usage
  declare -gA "${1}_NAME"
  declare -gA "${1}_FLAG"
  declare -gA "${1}_TYPE"
  declare -gA "${1}_LIST"
  declare -gA "${1}_OPTS"
  declare -ga "${1}_ARGS"
  declare -g "${1}_GOPT"=":"
}

lum::fn lum::getopts::def 
#$ <<id>> <<flag>> <<name>> <<type>> `{...}`
#
# Set argument parser option definitions.
#
# ((id))        The id of the parsing rules (see ``lum::getopts::init``).
#
# ((flag))      A unique single character for the option (e.g. "v").
#
# ((name))      A unique single-word sName for the option (e.g. "verbose").
#
# ((type))      The type of option determines how it handles values.
#           See ``lum::getopts::def.type`` for details.
#
# The last three arguments can be passed multiple times, so long as it's in
# complete sets of three. 
#
# See ``lum::getopts::def.err`` for a list of error codes.
#
lum::getopts::def() {
  [ $# -lt 4 ] && lum::help::usage
  local id="$1" sName sFlag sType sVar
  local -n setNames="${id}_NAME"
  local -n setFlags="${id}_FLAG"
  local -n setTypes="${id}_TYPE"
  local -n setList="${id}_LIST"
  local -n getOpts="${id}_GOPT"
  shift

  while [ $# -ge 3 ]; do
    sFlag="${1:0:1}" sName="$2" sType="${3:0:1}"
    if [ -n "${setNames[$sFlag]}" ]; then
      echo "duplicate sFlag: '$sFlag'" >&2
      exit $LUM_GETOPTS_ERR_FLAG_EXISTS
    fi
    if [ -n "${setFlags[$sName]}" ]; then
      echo "duplicate sFlag: '$sFlag'" >&2
      exit $LUM_GETOPTS_ERR_FLAG_EXISTS
    fi
    case "$sType" in
      '#')
        getOpts+="$sFlag"
      ;;
      ':'|'?')
        getOpts+="$sFlag:"
      ;;
      '+')
        getOpts+="$sFlag:"
        sVar="${id}_${sName}_VALS"
        setList[$sName]="$sVar"
        declare -ga "$sVar"
      ;;
      *)
        echo "invalid sType: '$sType'" >&2
        exit $LUM_GETOPTS_ERR_INVALID_TYPE
      ;;
    esac
    setNames[$sFlag]="$sName"
    setFlags[$sName]="$sFlag"
    setTypes[$sFlag]="$sType"
    shift 3
  done
}

lum::fn lum::getopts::def.err 2 -t 0 13
#$ `{int}`
#
# Error codes for ``lum::getopts::def`` function.
#
# ${LUM_GETOPTS_ERR_INVALID_TYPE}  - The ((type)) was not a valid type.
# ${LUM_GETOPTS_ERR_FLAG_EXISTS}  - The ((flag)) is already in use.
# ${LUM_GETOPTS_ERR_NAME_EXISTS}  - The ((name)) is already in use.
#
#: lum::getopts::def.err

lum::fn lum::getopts::def.type 2
#$ `{str}`
#
# The ((type)) argument for ``lum::getopts::def`` function.
#
# A single character that identifies the type of option.
#
# ``#`` = A numeric value indicating how many times the flag was specified.
#       If the flag is not specified, it will be ``0``.
# ``:`` = A flag with a value. If the flag is not specified, it will be empty.
#       If the flag is specified without a value, an error will be thrown.
# ``?`` = Mostly the same as ``:`` but if specified with no value, it will
#       set the value to ``-`` rather than throw an error.
# ``+`` = An array list flag that may be specified more than once.
#       This type is stored differently than other types.
#
#: lum::getopts::def.type

lum::fn lum::getopts::parse 
#$ <<id>> <<opts>> [[params...]]
#
# Parse command line parameters with ``getopts``
#
# ((id))      The id of the parsing rules (see ``lum::getopts::init``).
#
# ((opts))    Bitwise option.
#         ``1`` = Display error messages.
#         ``2`` = Return from function on error.
#
# The rest of the parameters are assumed to be the command line arguments.
#
# See ``lum::getopts::parse.err`` for a list of error codes.
#
lum::getopts::parse() {
  [ $# -lt 2 ] && lum::help::usage
  local id="$1" pArg sName sType OPTARG OPTIND
  local -i errs="$2"
  local -n setNames="${id}_NAME"
  local -n setTypes="${id}_TYPE"
  local -n setOpts="${id}_OPTS"
  local -n setArgs="${id}_ARGS"
  local -n getOpts="${id}_GOPT"
  shift 2

  while getopts "$getOpts" pArg; do
    if [ "$pArg" = "?" ]; then 
      lum::flag::is $errs 1 && echo "Invalid option: -${OPTARG}" >&2
      lum::flag::is $errs 2 && return $LUM_GETOPTS_ERR_INVALID_FLAG
    elif [ "$pArg" = ":" ]; then
      sType="${setTypes[$OPTARG]}"
      if [ "$sType" = "?" ]; then
        sName="${setNames[$OPTARG]}"
        setOpts[$sName]='-'
      else
        lum::flag::is $errs 1 && echo "Option '-${OPTARG}' requires a value" >&2
        lum::flag::is $errs 2 && return $LUM_GETOPTS_ERR_MISSING_VAL
      fi
    else
      sType="${setTypes[$pArg]}"
      sName="${setNames[$pArg]}"
      case "$sType" in
        '#')
          ((setOpts[$sName]++))
        ;;
        ':'|'?')
          setOpts[$sName]="$OPTARG"
        ;;
        '+')
          local -n avar="${id}_${sName}_VALS"
          avar+=("$OPTARG")
        ;;
      esac
    fi
  done

  shift $((OPTIND-1))
  setArgs+=("$@")

  return 0
}

lum::fn lum::getopts::parse.err 2 -t 0 13
#$ `{int}`
#
# Error codes for ``lum::getopts::parse`` function.
#
# ${LUM_GETOPTS_ERR_INVALID_FLAG}  - The ((flag)) was not recognized.
# ${LUM_GETOPTS_ERR_MISSING_VAL}  - The ((flag)) was missing a mandatory value.
#
#: lum::getopts::parse.err
