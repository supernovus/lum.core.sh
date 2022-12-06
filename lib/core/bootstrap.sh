#@lib: lum::core /bootstrap
#@desc: Submodule defining functions required by everything else.

### Proto-bootstrap functions

#$ lum::var - Declare global variables
#
# **Modifier options:**
#
# ``-A -a -i -r -n --``  → Following variables will use this declare type.
# ``-P <<prefix>>``        → Following variables will be prefixed with this.
# ``-S <<suffix>>``        → Following variables will be suffixed with this.
# ``<<T>>=[[end=-]] <<var>>``    → Set the context (see below). \
#                        ((T)) can be one of ``-a -A``.
#
# A ((prefix)) or ((suffix)) value of ``-`` is the same as ``""``.
#
# When in a context, none of the modifier options have any effect.
# The context will reset to default when the ((end)) value (default ``-``)
# is passed as an argument. 
# 
# **Declaration arguments:**
#
# See ``lum::var.args`` for regular (non-context) arguments.
# See ``lum::var.args-a`` for arguments in the ``-a`` context.
# See ``lum::var.args-A`` for arguments in the ``-A`` context.
#
lum::var() {
  local flag='--' cmode='--' prefix suffix cvar echar='-' varname
  while [ $# -gt 0 ]; do
    if [ "$cmode" != '--' -a "$1" = "$echar" ]; then
      cmode='--'
      shift
      continue
    fi
    case "$cmode" in
      -A)
        [ $# -lt 3 ] && lum::err "invalid # of args"
        if [ "${2:1:1}" = "?" ]; then
          [ -z "${cvar[$1]}" ] && cvar[$1]="$3"
        else
          cvar[$1]="$3"
        fi
        shift 3
      ;;
      -a)
        cvar+=("$1")
        shift
      ;;
      *) ## regular context
        case "$1" in
          --|-A|-a|-i|-r|-n|-ir|-ri)
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
          -a=*|-A=*)
            cmode="${1:0:2}"
            echar="${1:3}"
            [ -z "$echar" ] && echar='-'
            [ "$cmode" = "-a" -a $# -lt 3 ] && lum::help::usage
            [ "$cmode" = "-A" -a $# -lt 5 ] && lum::help::usage
            varname="$prefix$2$suffix"
            declare -g $cmode $varname
            local -n cvar="$varname"
            shift 2
          ;;
          *)
            varname="$prefix$1$suffix"
            if [ $# -ge 3 -a "${2:0:1}" = "=" ]; then
              [ "$flag" = "-A" -o "$flag" = "-a" ] && lum::help::usage
              if [ "${2:1:1}" = "?" ]; then
                declare -g $flag $varname
                local -n __var="$varname"
                [ -z "$__var" ] && __var="$3"
              else
                declare -g $flag $varname="$3"
              fi
              shift 3
            else
              [ "$flag" = "-n" ] && lum::help::usage
              declare -g $flag $varname
              shift
            fi
          ;;
        esac
      ;; ## end regular context
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

  local srcfile regfn 
  local -i srcCB=1 regCB=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --src)
        [ $# -lt 3 ] && lum::help::usage
        srcfile="$2"
        shift 2
      ;;
      --reg)
        [ $# -lt 3 ] && lum::help::usage
        regfn="$2"
        shift 2
      ;;
      -S)
        [ $# -lt 3 ] && lum::help::usage
        srcCB="$2"
        shift 2
      ;;
      -R)
        [ $# -lt 3 ] && lum::help::usage
        regCB="$2"
        shift 2
      ;;
      *)
        ## Anything else is a regular parameter.
        break
      ;;
    esac
  done

  [ -z "$srcfile" ] && srcfile="${BASH_SOURCE[$srcCB]}"
  [ -z "$regfn" ] && regfn="${FUNCNAME[$regCB]}"

  local fName="$1" fOpts="${2:-0}"
  LUM_FN_FILES[$fName]="$srcfile"
  LUM_FN_REGFN[$fName]="$regfn"
  LUM_FN_FLAGS[$fName]="$fOpts"

  if [ $# -gt 2 ]; then
    shift 2
    local hOpts=
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
          lum::fn::help -t "$fName" "$2" "$3"
          shift 3
        ;;
        -h)
          lum::fn::help -d -f "$fName" -m $2 $3
          shift 3
        ;;
        -H)
          lum::fn::help -f "$fName" -m $2 '+' $3
          shift 3
        ;;
        *)
          lum::warn "unrecognized lum::fn argument '$1'" 3
          shift
        ;;
      esac
    done
  fi
}

### Bootstrap variables

lum::var -P LUM_FN_ \
  -A FILES REGFN ALIAS FLAGS HELP \
  -i DEBUG = 0
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

lum::fn lum::fn::help
#$ `{...}`
# 
# Set help topic settings
#
# ``-f <<fn>>``             Set ((fn)) context.
#                       ``*`` is reserved for fallback defaults.
# ``-g <<group>>``          Set ((group)) context.
#
# ``-m <<mode>> <<group>>``   Set ((group)) for ((fn)):((mode)); set context.
#                       Group may be a special value:
#                         ``+`` → Use auto-generated id.
#                         ``=`` → Set context to current id for ((mode)).
#                       See ``lum::help`` for a list of ((mode)) values.
#
# <<def>>                 Add ((def)) to context ((group)).
#                       See ``lum::help.defs`` for details.
#
# See ``lum::fn::help.opts`` for more options.
#
lum::fn::help() {
  local fn gname prefix suffix key mode
  local -i case=0
  local -ri CS=0 LC=-1 UC=1
  while [ $# -gt 0 ]; do
    case "$1" in
      -f)
        [ $# -lt 2 ] && lum::help::usage
        fn="$2"
        shift 2
      ;;
      -g)
        [ $# -lt 2 ] && lum::help::usage
        gname="$(lum::var::id "$prefix$2$suffix" $case)"
        declare -ga "$gname"
        local -n group="$gname"
        shift 2
      ;;
      -m)
        [ $# -lt 3 -o -z "$fn" ] && lum::help::usage
        key="$2|$fn"
        case "$3" in 
          +)
            gname="$(lum::var::id "$prefix${fn}_$2$suffix" $case)"
          ;;
          =)
            gname="${LUM_FN_HELP[$key]}"
            [ -z "$gname" ] && lum::err "help group not set for $key"
          ;;
          *)
            gname="$(lum::var::id "$prefix$3$suffix" $case)"
          ;;
        esac
        if [ "$3" != '=' ]; then 
          declare -ga "$gname"
          LUM_FN_HELP[$key]="$gname"
        fi
        local -n group="$gname"
        shift 2
      ;;
      -i)
        [ -z "$gname" -o $# -lt -3 ] && lum::help::usage
        local incName="$(lum::var::id "$prefix$2$suffix" $case)"
        local slice="$3"
        if [ "$(lum::var::type $incName)" = "-a" ]; then
          local -n incGroup="$incName"
          group+=("${incGroup[@]:$slice}")
        fi
        shift 3
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
      --cs)
        case=$CS
        shift
      ;;
      --uc)
        case=$UC
        shift
      ;;
      --lc)
        case=$LC
        shift
      ;;
      -t)
        lum::err "help tags are dead; help groups reign!"
      ;;
      -d)
        prefix="LUM_FN_HELP_"
        suffix=
        case=$UC
        shift
      ;;
      -D)
        prefix=
        suffix=
        case=$CS
        shift
      ;;
      *)
        [ -z "$gname" ] && lum::help::usage
        group+=("$1")
        shift
      ;;
    esac
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

#lum::fn::helpTags '*' 0 5 1 3 2 0
#lum::fn::helpTags 'lum::fn::help' 0 7

lum::fn::help -d -f '*' \
  -m 0 default \
    fmt-pre param val syntax fmt-end \
  -m 1 usage \
    fmt-pre arg opt syntax \
  -m 2 summary \
    fmt-pre
  -g more -i default 0:4 -i usage 1 fmt-end

lum::fn lum::fn 1
lum::fn lum::var 5 -h 0 more

### Extra documentation

lum::fn lum::fn.flags 6
#$ - Help text settings (bitwise flags)
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

lum::fn lum::fn.defs 6
#$ - Extra lum::fn arguments
#
# Each of these has a specific number of arguments that MUST be passed.
# You can specify as many options as you like, as long as the argument
# count is correct. Below we'll list the mandatory argument count, and
# the target function that will be called with the arguments. The ``F``
# symbol refers to the ((funcname)) parameter.
#
# ((-a))   `{(3)}` → ``lum::fn::alias F $1{name} $2{opts} $3{list}``
# ((-A))   `{(2)}` → ``lum::fn::alias F $1{aname} $2{group}``
# ((-h))   `{(2)}` → ``lum::fn::help -d -f F -m $1{mode} $2{group}``
# ((-H))   `{(2)}` → ``lum::fn::help -f F -m $1{mode} '+' $2{args}``
#                  The ((args)) should be a quoted string of additional
#                  arguments separated by whitespace.
#
#: lum::fn.defs

lum::fn lum::fn.opts 6 -h 0 more
#$ - Advanced lum::fn options
#
# ``-S <<int>>``     Callback levels to source file (default ``1``)
# ``-R <<int>>``     Callback levels to register func (default ``0``)
#
# ``--src <<str>>``  Path to source file (overrides ``-S``)
# ``--reg <<str>>``  Name of register func (overrides ``-R``)
#
#: lum::fn.opts

lum::fn lum::var.args 6 -h 0 more
#$ - Regular arguments for lum::var
#
# <<var>>                → Declare variable ((var)) with no initial value. 
#                        Not supported by ``-n`` mode.
#
# <<var>> <<op>> <<val>>     → Declare variable ((var)) with value ((val)).
#                        Not supported by ``-a -A`` modes.
#
# The whitespace between ((var)), ((op)), and ((val)) is REQUIRED.
# Using `{""}` quotes around ((val)) is highly RECOMMENDED.
#
# Supported ((op)) values:
#
# ``=``    → Direct assignment of ((val)) value to the ((var)) variable.
# ``=?``   → Only assign ((val)) if ((var)) is not already set.
#
#: lum::var.args

lum::fn lum::var.args-a 6 -h 0 more
#$ - Arguments for $.syntax(-a=) mode in lum::var
#
# <<val>>    → Add ((val)) to context array.
#
#: lum::var.args-a

lum::fn lum::var.args-A 6 -h 0 more
#$ - Arguments for $.syntax(-A=) mode in lum::var
#
# <<key>> <<op>> <<val>> → Set context array key ((key)) to value ((val)).
#
# See ``lum::var.args`` for a description of ((op)) values.
#
#: lum::var.args-A

lum::fn lum::fn::help.opts 6 -h 0 more
#$ - More options for lum::fn::help
#
# ``-P <<prefix>>``         Following group variables prefixed with this.
# ``-S <<suffix>>``         Following group variables suffixed with this.
# ``--cs``                Following group names are case sensitive.
# ``--uc``                Following group names are forced to uppercase.
# ``--lc``                Following group names are forced to lowercase.
#
# ``-M <<mode>>``           Get the ((fn)):((mode)) group variable name.
#                       Output full variable name to ``STDOUT`` and return.
#
# ``-d``                   Following groups are built-in defaults.
# ``-D``                   Clear ``-d`` settings.
#
#: lum::fn::help.opts
