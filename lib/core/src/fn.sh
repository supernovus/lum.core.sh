#@lib: lum::core /fn
#@desc: Submodule for functions related to functions

lum::fn lum::fn::run 0 -h 0 more
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
#             <<listname>>  - The list of names.
#       ``3`` = Functions with a specific prefix.
#             <<prefix>>    - The prefix.
#             
# ((name))  The function name or an alias to the function.
#
lum::fn::run() {
  [ $# -lt 2 ] && lum::help::usage
  local mode="$1" fname aname cmd
  shift

  case "$mode" in
    2)
      [ $# -lt 2 ] && lum::help::usage
      lum::var::has "$1" "$2" || lum::fn::run-err "$2"
      fname="$2"
      shift 2
    ;;
    3)
      [ $# -lt 2 ] && lum::help::usage
      fname="$2"
      cmd="$1$2"
      shift 2
    ;;
    *)
      fname="$1"
      shift
    ;;
  esac

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
  lum::err "Unrecognized command '$err$1$end' specified" 1
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

lum::fn lum::fn::make
#$ <<name>> <<body...>>
#
# Build a dynamic function.
#
# ((name))        The name of the function to create.
#
# ((body))        The commands to run in the function.
#             Special characters such as ``$``, ``"``, etc. must be escaped
#             using ``\`` in order to be included as a part of the command.
#
lum::fn::make() {
  [ $# -lt 2 ] && lum::help::usage
  local -a func=('function' "$1()" '{')
  shift
  func+=("$@" ';' '}')
  lum::var::debug LUM_FN_DEBUG 1 "lum::fn::make ${func[@]}"
  eval "${func[@]}"
}

lum::fn lum::fn::list
#$ [[prefix]] 
#
# Show a list of functions.
#
# ((prefix))    Show only functions starting with this.
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
