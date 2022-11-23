#@lib: lum::core /bootstrap
#@desc: Submodule defining functions required by everything else.

### Proto-bootstrap functions

#$ lum::var `{...}`
#
# Declare global variables
#
# **Modifier arguments:**
#
# ``-A -a -i -r -n --``  → Following variables will use this declare type.
# ``-P <<prefix>>``        → Following variables will be prefixed with this.
# ``-S <<suffix>>``        → Following variables will be suffixed with this.
#
# A ((prefix)) or ((suffix)) value of ``-`` is the same as ``""``.
#
# **Declaration arguments:**
#
# <<var>>                → Declare variable ((var)) with no initial value. 
#                        The ``-n`` modifier CANNOT use this declaration.
# <<var>> = <<val>>        → Declare variable ((var)) with value ((val)).
#                        The ``-A -a`` modifiers CANNOT use this declaration.
#                        The whitespace around ``=`` is REQUIRED.
#                        Quotes around the ((val)) are RECOMMENDED.
#
lum::var() {
  local flag='--' prefix suffix
  while [ $# -gt 0 ]; do
    case "$1" in
      --|-A|-a|-i|-r|-n)
        flag="$1"
        shift
      ;;
      -P)
        prefix="$2"
        [ "$prefix" = '-' ] && prefix=
        shift 2
      ;;
      -S)
        suffix="$2"
        [ "$suffix" = '-' ] && suffix=
        shift 2
      ;;
      *)
        if [ $# -ge 3 -a "$2" = "=" ]; then
          [ "$flag" = "-a" -o "$flag" = "-A" ] && lum::help::usage
          declare -g $flag $prefix$1$suffix="$3"
          shift 3
        else
          [ "$flag" = "-n" ] && lum::help::usage
          declare -g $flag $prefix$1$suffix
          shift
        fi
      ;;
    esac
  done
}

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
  local caller
  if [ "$1" = "--from" -a $# -ge 3 ]; then
    caller="$2"
    shift 2
  else
    local -i callBack=1
    if [ "$1" = "-C" -a $# -ge 3 ]; then
      callBack=$2
      shift 2
    fi
    caller="${BASH_SOURCE[$callBack]}"
  fi

  local fName="$1" fOpts="${2:-0}"
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

### Bootstrap variables

lum::var -P LUM_FN_ -A FILES ALIAS FLAGS HELP_TAGS -i DEBUG
lum::var -A -P LUM_ALIAS_ FN GROUPS

### Main functions

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

lum::fn lum::use::load-subs
#$ [[path]]
#
# Load all sub-modules from a folder.
#
# ((path))     Optional path to load sub-modules from.
#          If not specified, we take the calling filename,
#          and add a ``.d`` to it, so ``./lib/foo.sh`` would 
#          look for sub-modules in ``./lib/foo.sh.d/*.sh``.
#
lum::use::load-subs() {
  local subPath="${1:-${BASH_SOURCE[1]}.d}" subFile
  if [ -d "$subPath" ]; then
    for subFile in "$subPath/"*.sh; do
      [ -f "$subFile" ] && . "$subFile"
    done
  fi
}

### Setup and registration

lum::fn::helpTags '*' 0 5 1 3 2 0

lum::fn lum::fn 1
lum::fn lum::var 1 -t 0 7

### Extra documentation

lum::fn lum::fn.flags 2
#$ `{int}`
#
# Bitwise flags modifying function/help behaviour.
#
# ``1``    The help text must start with an extended usage line,
#        including the officially registered function name.
#        If not set, the help text starts at the line below the 
#        call registering the function.
# ``2``    The help text must end with a `{#: funcname}` line.
#        Useful for documenting topics without an actual function.
#        If not set, the help text ends at the function declaration.
#        If no valid end-line is found, ends at first non-comment line.
# ``4``    The usage line is also the summary.
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
# ((-C))         <<int>>    The number of call back levels to find the
#                     file with the actual function definition.
#                     Default is ``1`` if not specified.
# ((--from))     <<str>>    The path to the actual source file.
#                     Obviously this overrules the ((-C)) option.
#
#: lum::fn.opts
