#$< lum::core /bootstrap
# Submodule defining functions required by everything else.

### Proto-bootstrap functions

## A variable used when rebooting.
[ $LUM_CORE_REBOOT -gt 0 ] && unset LUM_VAR_REBOOTED
declare -gA LUM_VAR_REBOOTED

#$ lum::debug - Simple debugging statements
#
# If no arguments are passed, output ``$LUM_DEBUG`` declaration and return.
#
# $i(-k); <<key>>          The namespace key for subsequent commands.
#                   Defaults to ``${FUNCNAME[1]}`` if not specified.
#                   If no further args, output current ((key)) value.
#
# $i(-s); <<cval>>         Set current ((key)) value to ((cval)) and return.
#
# $i(-t); <<tval>>         The test value for subsequent commands.
#                   Defaults to ``1`` if not specified.
#                   If no further args, return ``0`` if test passes,
#                   or return ``1`` if it fails.
#
# $i(-c);             Subsequent args are shell commands to be ran.
#                   If set, at least one arg must be passed.
#
# [[args...]]         If $i(-c); mode is on, a set of commands to run.
#                   Otherwise we output the args to $val(STDERR); with 
#                   ``«$key»`` prepended as a header.
#
# The test is: $fmt(\v ${LUM_DEBUG[ \p $key \v ]} \: \. >= \. \p $tval \;);
#
lum::debug() {
  if [ $# -eq 0 ]; then
    declare -p LUM_DEBUG
    return
  fi

  local dbgKey="${FUNCNAME[1]}"
  local -i tstVal=1 curVal=0 runMode=0

  while [ $# -gt 0 ]; do
    case "$1" in
      -k)
        [ $# -lt 2 ] && lum::help::usage
        dbgKey="$2"
        shift 2
        curVal="${LUM_DEBUG[$dbgKey]}"
        [ $# -eq 0 ] && echo "$curVal" && return
      ;;
      -s)
        [ $# -ne 2 ] && lum::help::usage
        LUM_DEBUG[$dbgKey]="$2"
        echo "$dbgKey = $dbgVal" >&2
        return
      ;;
      -t)
        [ $# -lt 2 ] && lum::help::usage
        tstVal="$2"
        shift 2
        if [ $# -eq 0 ]; then 
          [ "$curVal" -ge "$tstVal" ]
          return $?
        fi
      ;;
      -c)
        [ $# -lt 2 ] && lum::help::usage
        runMode=1
        shift
      ;;
      *)
        break
      ;;
    esac
  done

  local -i resCode
  [ "$curVal" -ge "$tstVal" ]
  resCode=$?

  if [ $resCode -eq 0 -a $# -gt 0 ]; then
    case "$runMode" in
      0)
        echo -e "«$dbgKey»" "$@" >&2
      ;;
      1)
        "$@"
        resCode=$?
      ;;
      *)
        lum::err "how did you get here?"
      ;;
    esac
  fi

  return $resCode
}

## Private function used by lum::var
lum::var+() {
  local VN="$1" VT="$2"
  if [ $LUM_CORE_REBOOT -gt 0 -a -z "${LUM_VAR_REBOOTED[$VN]}" ]; then
    unset $VN
    LUM_VAR_REBOOTED[$VN]="$VT"
    lum::debug -k lum::var -t 2 "REBOOTED $VT $VN"
  fi
  declare -g $VT $VN
  lum::debug -k lum::var -t 3 -c declare -p $VN
}

#$ lum::var - Declare global variables
#
# $h(Modifier options:);
#
# ``-A -a -i -n --``     → Following variables will use this declare type.
# ``-P <<prefix>>``        → Following variables will be prefixed with this.
# ``-S <<suffix>>``        → Following variables will be suffixed with this.
#
# <<T>>=[[end='--']] <<var>> → Set the context (see below).
#                        ((T)) can be one of ``-a -A``.
#
# A ((prefix)) or ((suffix)) value of ``-`` is the same as ``""``.
#
# When in a context, none of the modifier options have any effect.
# The context will reset to default when the ((end)) value (default ``-``)
# is passed as an argument. 
#
#$line(See also);
# $see(,args);    → For regular (non-context) arguments.
# $see(,args-a);  → For arguments in the ``-a`` context.
# $see(,args-A);  → For arguments in the ``-A`` context.
#
lum::var() {
  local flag='--' cmode='--' prefix suffix cvar echar varname
  while [ $# -gt 0 ]; do
    if [ "$cmode" != '--' -a "$1" = "$echar" ]; then
      cmode='--'
      shift
      continue
    fi
    case "$cmode" in
      -A)
        [ $# -lt 3 ] && lum::help::usage
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
          --|-A|-a|-i|-n)
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
            lum::var+ $varname $cmode
            local -n cvar="$varname"
            shift 2
          ;;
          *)
            varname="$prefix$1$suffix"
            if [ $# -ge 3 -a "${2:0:1}" = "=" ]; then
              [ "$flag" = "-A" -o "$flag" = "-a" ] && lum::help::usage
              if [ "${2:1:1}" = "?" -a $LUM_CORE_REBOOT -le 0 ]; then
                declare -g $flag $varname
                local -n __var="$varname"
                [ -z "$__var" ] && __var="$3"
              else
                declare -g $flag $varname="$3"
              fi
              shift 3
            else
              [ "$flag" = "-n" ] && lum::help::usage
              lum::var+ $varname $flag
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
#
# ((flags))      Bitwise flags that modify the definition.
#            See ``lum::fn.flags`` for details.
#
#$line(See also);
# $see(,opts); → For ((opts)) preceeding the main arguments.
# $see(,defs); → For ((defs)) following the main arguments.
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
          echo "-t used $srcfile:${BASH_LINENO[$srcCB]}" >&2
          shift 3
        ;;
        -h)
          lum::fn::help --core -f "$fName" -m "$2" $3
          shift 3
        ;;
        -H)
          lum::fn::help --fn -f "$fName" -m "$2" '+' $3
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

lum::var -A \
  -P LUM_FN_ FILES REGFN ALIAS FLAGS HELP HELP_EXT \
  -P LUM_ALIAS_ FN GROUPS

### Main functions

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

lum::fn lum::fn::alias
#$ <<fname>> <<alias>> [[opts=0]] [[list=0]]
#
# Create a function alias.
#
# This is primarily only used by the help system, but
# will also be used for command line dispatch as well.
#
# ((fname))      The full function name (e.g. ``myapp::coolFunc``).
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
    [ -n "${LUM_FN_ALIAS[$fName]}" ] && ! lum::flag::is $opts $OVWR && return
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
# ``-m <<mode>> <<group>>``   Set ((group)) context, and assign to ((fn)):((mode)).
#                       ((group)) may be a group id, or a special value:
#                         ``+`` → Use auto-generated id.
#                         ``=`` → Set context to current id for ((mode)).
#                       ((mode)) is a help mode int, or a sub-topic string.
#
# <<def>>                 Add ((def)) to context ((group)).
#
#$line(See also);
# $see(lum::help::tmpl 20); → A list of ((def)) values.
# $see(lum::help 20); → A list of help ((mode)) int values.
# $see(,opts 20); → Advanced options.
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
        lum::var+ $gname -a
        local -n group="$gname"
        shift 2
      ;;
      -m)
        [ $# -lt 3 -o -z "$fn" ] && lum::help::usage
        mode="$2"
        key="$mode|$fn"
        case "$3" in 
          +)
            gname="$(lum::var::id "$prefix${fn}_$mode$suffix" $case)"
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
          lum::var+ $gname -a
          LUM_FN_HELP[$key]="$gname"
        fi
        local -n group="$gname"
        shift 3
      ;;
      -M)
        [ $# -lt 2 -o -z "$fn" ] && lum::help::usage
        key="$2|$fn"
        gname="${LUM_FN_HELP[$key]}"
        [ -z "$gname" ] && return 1
        echo "$gname"
        return 0
      ;;
      -i)
        [ -z "$gname" -o $# -lt -3 ] && lum::help::usage
        local incName="$(lum::var::id "$prefix$2$suffix" $case)"
        local -i incInd="${3/:*}" incLen
        [ "$3" = "$incInd" ] && incLen=0 || incLen="${3/*:}"
        [ $incLen -eq 0 ] && incLen="${#incGroup[@]}"
        if [ "$(lum::var::type $incName)" = "-a" ]; then
          local -n incGroup="$incName"
          group+=("${incGroup[@]:$incInd:$incLen}")
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
      --core)
        prefix="LUM_FN_HELP_"
        suffix=
        case=$UC
        shift
      ;;
      --fn)
        prefix=
        suffix="_HELP"
        case=$UC
        shift
      ;;
      *)
        if [ -n "${LUM_FN_HELP_EXT[$1]}" ]; then
          local -i extShift=1
          ${LUM_FN_HELP_EXT[$1]} "$@"
          shift $extShift
        elif [ -n "$gname" ]; then
          group+=("$1")
          shift
        else
          lum::help::usage
        fi
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

lum::fn::help --core -f '*' \
  -m 0 default \
    fmt-pre value param syntax fmt-end \
  -m 1 usage \
    fmt-pre arg opt syntax fmt-end \
  -m 2 summary \
    fmt-pre \
  -g more fmt-pre value param arg opt syntax fmt-end \
  -g docs fmt-pre value syntax fmt-end escape

lum::fn lum::fn 1 -h opts more
lum::fn lum::var 5 -h 0 more
lum::fn lum::debug 5 -h 0 more
lum::fn::help --core -f 'lum::fn::help' -m 0 more

### Extra documentation

#$ lum::fn,flags - Help text settings (bitwise flags)
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
#: lum::fn,flags

#$ lum::fn,defs - Extra lum::fn arguments
#
# Each of these has a specific number of arguments that MUST be passed.
# The required arguments will be shown below in a ``$1{name}`` format,
# where ``1`` is the positional argument number, and ``name`` is simply a
# description of the argument. The ``$F`` symbol is the mandatory ((name))
# argument passed to $val(lum::fn); before any of these arguments.
#
# ((-a))   → lum::fn::alias $i($F); (($1{name} $2{opts} $3{list}))
# ((-A))   → lum::fn::alias (($F $1{aname} $2{group}))
# ((-h))   → lum::fn::help --core -f (($F)) -m (($1{mode} $2{group}))
# ((-H))   → lum::fn::help --fn -f (($F)) -m (($1{mode})) '+' (($2{args}))
#        The ((args)) should be a quoted string of additional
#        arguments separated by whitespace.
#
#: lum::fn,defs

#$ lum::fn,opts - Advanced lum::fn options
#
# ``-S <<int>>``     Callback levels to source file (default ``1``)
# ``-R <<int>>``     Callback levels to register func (default ``0``)
#
# ``--src <<str>>``  Path to source file (overrides ``-S``)
# ``--reg <<str>>``  Name of register func (overrides ``-R``)
#
#: lum::fn,opts

#$ lum::var,args - Regular arguments for lum::var
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
#: lum::var,args

#$ lum::var,args-a - Arguments for $.syntax(-a=) mode in lum::var
#
# <<val>>    → Add ((val)) to context array.
#
#: lum::var,args-a

#$ lum::var,args-A - Arguments for $.syntax(-A=) mode in lum::var
#
# <<key>> <<op>> <<val>> → Set context array key ((key)) to value ((val)).
#
# See $see(lum::var,args); for a description of ((op)) values.
#
#: lum::var,args-A

#$ lum::fn::help,opts - More options for lum::fn::help
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
# ``--core``                Following groups use core settings.
# ``--fn``                  Following groups use fn settings.
#
#: lum::fn::help,opts
