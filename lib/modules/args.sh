## Simple argument handling stuff

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

[ -z "$LUM_ARGS_ERR_INVALID_TYPE" ] && LUM_ARGS_ERR_INVALID_TYPE=170
[ -z "$LUM_ARGS_ERR_INVALID_FLAG" ] && LUM_ARGS_ERR_INVALID_FLAG=171
[ -z "$LUM_ARGS_ERR_MISSING_VAL"  ] && LUM_ARGS_ERR_MISSING_VAL=172
[ -z "$LUM_ARGS_ERR_FLAG_EXISTS"  ] && LUM_ARGS_ERR_FLAG_EXISTS=173
[ -z "$LUM_ARGS_ERR_NAME_EXISTS"  ] && LUM_ARGS_ERR_NAME_EXISTS=174
[ -z "$LUM_ARGS_ERR_INVALID_NAME" ] && LUM_ARGS_ERR_INVALID_NAME=175

lum::lib lum::args $LUM_CORE

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

lum::fn lum::args::new
#$ <<id>> <<optvar>> [[posvar]]
#
# Create a new arguments parser.
#
# ((id))    A unique id. Must be a valid variable identifier.
#
# We will create several global variables for storing values.
# 
# `{[-A]}` ``${id}_NAME``         A map of ((flag)) to ((name)).
# `{[-A]}` ``${id}_FLAG``         A map of ((name)) to ((flag)).
# `{[-A]}` ``${id}_TYPE``         A map of ((flag)) to ((type)).
# `{[-A]}` ``${id}_GOPT``         A getopts format string.
# `{[-A]}` ``${id}_OPTS``         Parsed named options.
# `{[-a]}` ``${id}_ARGS``         Parsed positional arguments.
#
# The ``lum::args::opt`` function may also create more variables.
#
# `{[-a]}` ``${id}_${name}_VALS``   One for each ``+`` type flag.
#
lum::args::new() {
  [ $# -eq 0 ] && lum::help::usage
  declare -gA "${1}_OPTS"
  declare -ga "${1}_ARGS"
  declare -gA "${1}_NAME"
  declare -gA "${1}_TYPE"
  declare -gA "${1}_GOPT"=":"
}

lum::fn lum::args::set 
#$ <<id>> <<flag>> <<name>> <<type>> `{...}`
#
# Set argument parser option definitions.
#
# ((id))        The id of the parser (see ``lum::args::new``).
#
# ((flag))      A unique single character for the option (e.g. "v").
#
# ((name))      A unique single-word name for the option (e.g. "verbose").
#
# ((type))      The type of option determines how it handles values.
#           See ``lum::args::set.type`` for details.
#
# The last three arguments can be passed multiple times, so long as it's in
# complete sets of three. 
#
# See ``lum::args::set.err`` for a list of error codes.
#
lum::args::set() {
  [ $# -lt 4 ] && lum::help::usage
  local id="$1" name flag type
  local -n names="${id}_NAME"
  local -n flags="${id}_FLAG"
  local -n types="${id}_TYPE"
  local -n gopts="${id}_GOPT"
  shift
  while [ $# -ge 3 ]; do
    flag="${1:0:1}" name="$2" type="${3:0:1}"
    if [ -n "${names[$flag]}" ]; then
      echo "duplicate flag: '$flag'" >&2
      exit $LUM_ARGS_ERR_FLAG_EXISTS
    fi
    if [ -n "${flags[$name]}" ]; then
      echo "duplicate flag: '$flag'" >&2
      exit $LUM_ARGS_ERR_FLAG_EXISTS
    fi
    case "$type" in
      '#')
        gopts+=$flag
      ;;
      :|?)
        getopts+="$flag:"
      ;;
      +)
        getopts+="$flag:"
        declare -ga "${id}_${name}_VALS"
      ;;
      *)
        echo "invalid type: '$type'" >&2
        exit $LUM_ARGS_ERR_INVALID_TYPE
      ;;
    esac
    names[$flag]="$name"
    flags[$name]="$flag"
    types[$flag]="$type"
    shift 3
  done
}

lum::fn lum::args::set.err 2 -t 0 13
#$ `{int}`
#
# Error codes for ``lum::args::set`` function.
#
# ${LUM_ARGS_ERR_INVALID_TYPE}  - The ((type)) was not a valid type.
# ${LUM_ARGS_ERR_FLAG_EXISTS}  - The ((flag)) is already in use.
# ${LUM_ARGS_ERR_NAME_EXISTS}  - The ((name)) is already in use.
#
#: lum::args::set.err

lum::fn lum::args::set.type 2
#$ `{str}`
#
# The ((type)) argument for ``lum::args::set`` function.
#
# A single character that identifies the type of option.
#
# ``#`` = A numeric value indicating how many times the flag was specified.
#       If the flag is not specified, it will be ``0``.
# ``:`` = A flag with a value. If the flag is not specified, it will be empty.
#       If the flag is specified without a value, an error will be thrown.
# ``?`` = Mostly the same as ``:`` but if specified with no value, it will
#       set the value to ``-`` rather than throw an error.
# ``+`` = A flag with a value that may be specified more than once.
#       This type is stored in a different variable than other types.
#
#: lum::args::set.type

lum::fn lum::args::parse 
#$ <<id>> <<opts>> [[params...]]
#
# Parse command line parameters with ``getopts``
#
# ((id))      The id of the parser (see ``lum::args::new``)
#
# ((opts))    Bitwise option flags.
#         ``1`` = Display error messages.
#         ``2`` = Return from function on error.
#
# The rest of the parameters are assumed to be the command line arguments.
#
# See ``lum::args::parse.err`` for a list of error codes.
#
lum::args::parse() {
  [ $# -lt 2 ] && lum::help::usage
  local id="$1" arg name type OPTARG OPTIND
  local -i errs="$2"
  local -n names="${id}_NAME"
  local -n types="${id}_TYPE"
  local -n opts="${id}_OPTS"
  local -n args="${id}_ARGS"
  local -n gopts="${id}_GOPT"
  shift 2

  while getopts "$gopts" arg; do
    if [ "$arg" = "?" ]; then 
      lum::flag::is $errs 1 && echo "Invalid option: -${OPTARG}" >&2
      lum::flag::is $errs 2 && return $LUM_ARGS_ERR_INVALID_FLAG
    elif [ "$arg" = ":" ]; then
      type="${types[$OPTARG]}"
      if [ "$type" = "?" ]; then
        name="${names[$OPTARG]}"
        opts[$name]='-'
      else
        lum::flag::is $errs 1 && echo "Option '-${OPTARG}' requires a value" >&2
        lum::flag::is $errs 2 && return $LUM_ARGS_ERR_MISSING_VAL
      fi
    else
      type="${types[$arg]}"
      name="${names[$arg]}"
      case "$type" in
        '#')
          ((opts[$name]++))
        ;;
        :|?)
          opts[$name]="$OPTARG"
        ;;
        +)
          local -n avar="${id}_${name}_VALS"
          avar+=("$OPTARG")
        ;;
      esac
    fi
  done

  shift $((OPTIND-1))
  args+=("$@")

  return 0
}

lum::fn lum::args::parse.err 2 -t 0 13
#$ `{int}`
#
# Error codes for ``lum::args::parse`` function.
#
# ${LUM_ARGS_ERR_INVALID_FLAG}  - The ((flag)) was not recognized.
# ${LUM_ARGS_ERR_MISSING_VAL}  - The ((flag)) was missing a mandatory value.
#
#: lum::args::parse.err

lum::fn lum::args::get
#$ <<id>> <<name>>
#
# Get the value associated with the specified name.
# It returns the value in the ``STDOUT`` output stream.
#
# This transparently handles the different types of options.
# For the ((name)) ``-`` or options of type ``+`` it returns an array.
# for any other types it returns the singular value associated.
#
# ((id))      The id of the parser.
#
# ((name))    The name of the option.
#             You can also use the ((flag)), we'll look up the name.
#             If this is ``-`` we return the positional arguments.
#
# See ``lum::args::get.err`` for a list of error codes.
#
lum::args::get() {
  [ $# -eq 0 ] && lum::help::usage
  local id="$1" name="$2" type flag
  local -n names="${id}_NAME"
  local -n flags="${id}_FLAG"
  local -n types="${id}_TYPE"
  local -n opts="${id}_OPTS"
  local -n args="${id}_ARGS"

  if [ "$name" = "-" ]; then
    ## The simplest of them all.
    echo "${args[@]}"
    return 0
  elif [ "${#name}" -eq 1 -a -n "${names[$name]}" ]; then
    ## The flag was passed instead of the name.
    flag="$name"
    name="${names[$flag]}"
  elif [ -n "${flags[$name]}" ]; then
    ## All is good in the world.
    flag="${flags[$name]}"
  else
    ## Nope.
    echo "Invalid name: '$name'" >&2
    return $LUM_ARGS_ERR_INVALID_NAME
  fi

  type="${types[$flag]}"

  if [ "$type" = "+" ]; then
    local -n avar="${id}_${name}_VALS"
    echo "${avar[@]}"
  else
    echo "${opts[$name]}"
  fi

  return 0
}

lum::fn lum::args::get.err 2 -t 0 13
#$ `{int}`
#
# Error codes for ``lum::args::get`` function.
#
# ${LUM_ARGS_ERR_INVALID_FLAG}  - The ((flag)) was not recognized.
# ${LUM_ARGS_ERR_INVALID_NAME}  - The ((name)) was not recognized.
#
#: lum::args::get.err

