## core lum::fn 

declare -gA LUM_FN_FILES
declare -gA LUM_FN_ALIAS
declare -gA LUM_FN_FLAGS
declare -gA LUM_FN_HELP_TAGS
declare -gA LUM_ALIAS_FN
declare -gA LUM_ALIAS_GROUPS

#$ lum::fn `{opts...}` <<name>> [[flags=0]] `{defs...}`
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
# For ((opts)) preceeding the main arguments, see: ``lum::fn.opts``
# For ((defs)) following the main arguments, see: ``lum::fn.defs``
#
lum::fn() {
  [ $# -lt 1 ] && lum::help::usage
  local -i callBack=1
  if [ "$1" = "-C" -a $# -ge 3 ]; then
    callBack=$2
    shift 2
  fi

  local caller="${BASH_SOURCE[$callBack]}" fName="$1" fOpts="${2:-0}"
  LUM_FN_FILES[$fName]="$caller"
  LUM_FN_FLAGS[$fName]="$fOpts"
  if [ $# -gt 2 ]; then
    shift 2
    while [ $# -gt 0 ]; do
      case "$1" in 
        -a)
          lum::fn::alias "$fName" "$2" "$3" "$4"
          shift 4
        ;;
        -A)
          lum::fn::alias "$fName" "$2" "$3"
          shift 3
        ;;
        -t)
          lum::fn::helpTags "$fName" "$2" "$3"
          shift 3
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
# ((opts))       Options for the alias definition (as bitwise flags).
#            ``1`` = This is the primary name shown in the help/usage text.
#                  Will not overwrite an existing primary by default.
#            ``2`` = If flag ``1`` is set, this will allow overwriting.
#
#            This may also be the name of an alias group, in which case
#            the real ((opts)) and ((list)) will be obtained from there.
#
# ((list))       The name of a command list to add the alias to.
#            It must be a valid global variable name, and it must be
#            declared as a flat array (``-a``) variable.
#            If set as ``0`` this is skipped.
# 
lum::fn::alias() {
  [ $# -lt 2 ] && lum::help::usage
  local fName="$1" aName="$2" opts="${3:-0}" listname="${4:-0}"
  local PRI=1 OVWR=2
  LUM_ALIAS_FN[$aName]="$fName"

  if [ "$listname" = 0 -a -n "${LUM_ALIAS_GROUPS[$opts]}" ]; then
    local -a group=(${LUM_ALIAS_GROUPS[$opts]})
    opts=${group[0]}
    listname="${group[1]}"
  fi

  if [ -n "$listname" -a "$listname" != "0" ]; then 
    local -n list="$listname"
    list+=($aName)
  fi

  if lum::flag::is $opts $PRI; then 
    [ -n "${LUM_FN_ALIAS[$fName]}" ] && lum::flag::not $opts $OVWR && return
    LUM_FN_ALIAS[$fName]="$aName"
  fi
}

lum::fn lum::fn::alias::group 
#$ <<name>> <<opts>> <<list>>
#
# Create an alias group with set options and a list.
#
# ((name))      The name of the group to create.
# ((opts))      The options as an integer of bitwise flags.
# ((list))      The name of a list to add the alias to.
#
lum::fn::alias::group() {
  [ $# -ne 3 ] && lum::help::usage
  local name="$1" opts="${2:-0}" list="${3:-0}"
  LUM_ALIAS_GROUPS[$name]="$opts $list"
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
    shift 2
  done
}

lum::fn lum::fn::run
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
  echo "Unrecognized command '$err$1$end' specified" >&2
  exit 1
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

### Extra documentation

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

lum::fn lum::fn.defs 2
#$ `{*}`
#
# Extra definition options for the ``lum::fn`` function.
#
# Each of these has a specific number of arguments that MUST be passed.
# You can specify as many options as you like, as long as the argument
# count is correct. Below we'll list the mandatory argument count, and
# the target function that will be called with the arguments. The ``F``
# symbol refers to the ((funcname)) parameter.
#
# ((-a))   `{(3)}` → ``lum::fn::alias F aname opts list``
# ((-A))   `{(2)}` → ``lum::fn::alias F aname group``
# ((-t))   `{(2)}` → ``lum::fn::helpTags F mode tags``
#
#: lum::fn.defs

lum::fn lum::fn.opts 2 -t 0 7
#$ `{*}`
#
# Options to change function definition settings.
#
# ((-C)) <<int>>    The number of call back levels to find the
#             file with the actual function definition.
#             Default is ``1`` if not specified.
#
#: lum::fn.opts
