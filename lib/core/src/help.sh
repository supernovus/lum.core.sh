#$< lum::core /help
# Fundamental features for the help system

lum::var -A LUM_THEME -i \
  LUM_WARN_LVL =? -1 \
  LUM_ERR_LVL  =? 2 \
  -P LUM_USAGE_ \
  MORE_INFO =? 1 \
  LVL       =? -1 \
  -- TITLE  =? "usage: " \
  -P LUM_HELP_ \
  COMMAND \
  DEFAULT_TOPIC \
  START_MARKER = '#$' \
  END_MARKER   = '#:' \
  -A= WANT \
    all     = 0 \
    usage   = 1 \
    summary = 2 \
    -

lum::fn lum::help
#$ <<name>> [[mode=0]]
#
# Show help information for a function.
#
# ((name))      Name of the function (e.g. ``lum::help``)
#           If set to ``0``, uses the name of the calling function.
#           Can specify a sub-topic using a comma (e.g ``lum::help,defs``).
#
# ((mode))      What help text we want to return:
#           ``0`` = Return the entire help text.
#           ``1`` = Return only the usage line.
#           ``2`` = Return only the summary line.
#
lum::help() {
  local prefind S tName="${1:-0}" fName sName lName dName rName
  local -i want="${2:-0}" FS=0 FE=0 SU=0
  local err="${LUM_THEME[error]}"
  local end="${LUM_THEME[end]}"
  local -n WANT=LUM_HELP_WANT
  local -i lineWidth="$(lum::help::width)"

  if [ "$tName" = "0" ]; then 
    fName="${LUM_HELP_DEFAULT_TOPIC:-${FUNCNAME[1]}}"
    tName="$fName"
  else
    fName="${tName/,*}"
    [ "$fName" != "$tName" ] && sName="${tName/*,}"
  fi

  if [ -n "${LUM_ALIAS_FN[$fName]}" ]; then
    rName="$fName"
    fName="${LUM_ALIAS_FN[$fName]}"
  fi
  
  srcfile="${LUM_FN_FILES[$fName]}"

  if [ -z "$srcfile" -o ! -f "$srcfile" ]; then
    echo "function '$err$fName$end' not recognized" >&2
    return 1
  fi
  
  local -n HTAGS="LUM_FN_HELP_TAGS" 
  local usageTags wantTags

  if [ -n "$sName" ]; then
    ## Sub-topics are treated differently.
    FS=1 FE=1 SU=1 
    lName="$fName,$sName"

    local -a _tkeys=("$sName|$fName" "$want|$fName" "$want|*")
    local _tk

    for _tk in "${_tkeys[@]}"; do
      wantTags="${LUM_FN_HELP[$_tk]}"
      [ -n "$wantTags" ] && break
    done
    usageTags="$wantTags"
  else
    local -i flags="${LUM_FN_FLAGS[$fName]:-0}"
    local _tk="$want|$fName" _ak="$want|*"

    lum::flag::is $flags 1 && FS=1
    lum::flag::is $flags 2 && FE=1
    lum::flag::is $flags 4 && SU=1

    lName="$fName"
    wantTags="${LUM_FN_HELP[$_tk]:-${LUM_FN_HELP[$_ak]}}"

    if [ "$want" = ${WANT[usage]} ]; then 
      usageTags="$wantTags" 
    else 
      _tk="${WANT[usage]}|$fName"
      _ak="${WANT[usage]}|*"
      usageTags="${LUM_FN_HELP[$_tk]:-${LUM_FN_HELP[$_ak]}}"
    fi
  fi

  [ -z "$wantTags" ] && lum::err "invalid help mode '$want' specified"

  if [ -n "${LUM_FN_ALIAS[$fName]}" ]; then
    dName="${LUM_FN_ALIAS[$fName]}"
  elif [ $FS -eq 0 ]; then
    dName="$fName"
  fi

  if [ $FS -eq 1 ]; then
    prefind="${LUM_HELP_START_MARKER} $lName"
  else
    local regfn="${LUM_FN_REGFN[$fName]}"
    prefind="$regfn $fName"
  fi

  #echo "tName='$tName'; fName='$fName'; sName='$sName' wantTags='$wantTags'" >&2
  #echo "<help> fName='$fName' srcfile='$srcfile'"

  S=$(grep -nm 1 "^$prefind" "$srcfile" | cut -d: -f1)

  if [ -z "$S" ]; then
    echo "no help definition found for '$err$tName$end'" >&2
    return 2
  fi

  [ $FS -eq 0 ] && ((S++))

  [ $LUM_HELP_TMPL_INIT -ne 1 ] && lum::help::tmpl--init

  ## Friendly map of settings for template extensions.
  local -A helpOptions=(\
    [reqid]="$tName" \
    [reqfn]="$rName" \
    [fn]="$fName" \
    [show]="$dName" \
    [sub]="$sName" \
    [id]="$lName" \
    [mode]="$want" \
  )

  [ -n "$dName" ] && helpOptions[root]="$dName" || helpOptions[root]="$fName"

  if [ $want = ${WANT[summary]} ]; then
    local start
    if [ $SU -eq 1 ]; then 
      start="$LUM_HELP_START_MARKER"
    else
      start='#'
      ((S+=2))
    fi
    local sexp="s/^${start}\s*//"
    sexp+=";s/^${lName}\s*//"
    sexp+=";s/^-\s*//"
    sed -n "${S}{$sexp;p}" "$srcfile" | lum::help::tmpl $wantTags
    return 0
  fi

  local output="$(sed -n "${S}{s/$LUM_HELP_START_MARKER\s*/$dName /;p}" "$srcfile")"
  [ $FS -eq 1 -a -n "$dName" ] && output="${output/$lName}"
  echo "$output" | lum::help::tmpl $usageTags
  [ $want = ${WANT[usage]} ] && return 0

  ((S++))

  local suffind E
  if [ $FE -eq 1 ]; then 
    suffind="${LUM_HELP_END_MARKER} $lName"
  else 
    suffind="${fName}\s*()"
  fi
  E=$(grep -nm 1 "^$suffind" "$srcfile" | cut -d: -f1)

  if [ -n "$E" ]; then
    ((E--))
    sed -n "${S},${E}{s/^#//;p}" "$srcfile" | lum::help::tmpl $wantTags
  else
    output=""
    local line
    while true; do
      line="$(sed -n "${S}p" "$srcfile")"
      [ "${line:0:1}" != "#" ] && break
      output+="${line:1}"
      output+=$'\n'
      ((S++))
    done
    echo "$output" | lum::help::tmpl $wantTags
  fi

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
  local -i S=${1:-1} E=${#BASH_SOURCE[@]} L
  local mc="${LUM_THEME[diag.func]}"
  local fc="${LUM_THEME[diag.file]}"
  local lc="${LUM_THEME[diag.line]}"
  local ec="${LUM_THEME[end]}"
  local fn sf ln
  ((E--))
  for (( L=$S; L<$E; L++ ))
  do
    fn="${FUNCNAME[$L]}"
    sf="${BASH_SOURCE[$L]}"
    ln="${BASH_LINENO[$L]}"
    echo " → $mc$fn$ec ($fc$sf$ec:$lc$ln$ec)"
  done
}

lum::fn lum::warn
#$ <<message>> [[diagLvl=-1]]
#
# Issue a warning message
#
# ((message))      The message to output to ``STDERR`` using ``echo -e``.
#
# ((diagLvl))      Passed to ``lum::help::diag`` if greater than ``-1``.
#              Default can be changed via ``LUM_WARN_LVL``
#
lum::warn() {
  [ $# -lt 1 ] && lum::help::usage
  local msg="$1" 
  local -i wantLvl="${2:-$LUM_WARN_LVL}"
  echo -e "$1" >&2
  [ $wantLvl -gt -1 ] && lum::help::diag $wantLvl >&2
}

lum::fn lum::err
#$ <<message>> [[errcode=1]] [[diagLvl=2]] 
#
# Issue an error message
#
# ((message))      The message to output to ``STDERR`` using ``echo -e``.
#
# ((errcode))      Error code to return when exiting script.
#              If set to ``-1`` then exit won't be called.
#
# ((diagLvl))      Passed to ``lum::help::diag`` if greater than ``-1``.
#              Default can be changed via ``LUM_ERR_LVL``.
#
lum::err() {
  [ $# -lt 1 ] && lum::help::usage
  local msg="$1" 
  local -i errCode="${2:-1}" wantLvl="${3:-$LUM_ERR_LVL}"
  echo -e "$1" >&2
  [ $wantLvl -gt -1 ] && lum::help::diag $wantLvl >&2
  exit $errCode
}

lum::fn lum::help::usage 0 -h 0 more
#$ [[options...]] [[message]]
#
# Show usage summary for a function.
#
# ((message))           Optional error message.
#
# ((options)):
#
#  $i(-f); <<funcname>>    Name of the function (e.g. ``lum::help::usage``)
#                   If not specified, we use the calling function.
#  $i(-e); <<errcode>>     Error code to return when exiting script.
#                   If set to ``-1``, exit won't be called. Default: ``100``
#  $i(-d); <<diagLvl>>     Passed to ``lum::help::diag`` if greater than ``-1``.
#                   Default can be changed via ``LUM_USAGE_LVL``. 
lum::help::usage() {
  local fName
  local -i errCode=100 wantLvl=$LUM_USAGE_LVL msgLvl=-1

  while [ $# -gt 0 ]; do
    case "$1" in
      -f)
        fName="$2"
        shift 2
      ;;
      -e)
        errCode="$2"
        shift 2
      ;;
      -d)
        wantLvl="$2"
        shift 2
      ;;
      *)
        break;
      ;;
    esac
  done

  if [ -z "$fName" ]; then
    fName="${FUNCNAME[1]}"
  fi

  local want="$(lum::help $fName 1)"
  [ -z "$want" ] && msgLvl=$wantLvl

  if [ -n "$1" ]; then
    lum::warn "${LUM_THEME[error]}$1${LUM_THEME[end]}" $msgLvl
  fi

  if [ -n "$want" ]; then
    [ "$LUM_USAGE_TITLE" != "0" ] && want="${LUM_USAGE_TITLE}$want"
    lum::warn "$want" $wantLvl
    if [ -n "$LUM_HELP_COMMAND" -a "$LUM_USAGE_MORE_INFO" != "0" ]; then
      lum::help::moreinfo >&2
    fi
  fi

  exit $errCode
}

lum::fn lum::help::register 0 -h 0 more
#$ [[options...]] [[cmd...=help$spc{};--help]]
#
# Register a help command for a CLI script
#
# ((cmd))         A command name to use for help.
# ((options)):
#
#  $i(-l); <<list>>  Subsequent ((cmd)) args should be added to this list.
# 
# Additional ((cmd)) names may be specified, but only the first will
# be set as the primary name and will be assigned to ``LUM_HELP_COMMAND``.
# You may specify ((options)) between sets of ((cmd)) arguments.
#
lum::help::register() {
  if [ $# -eq 0 ]; then
    ## Use basic defaults.
    lum::help::register help --help
    return
  fi

  local list=0
  local -i added=0
  while [ $# -gt 0 ]; do
    case "$1" in 
      -l)
        list="$2"
        shift 2
      ;;
      *)
        if [ -z "$LUM_HELP_COMMAND" ]; then
          lum::fn::alias lum::help "$1" 1 "$list"
          LUM_HELP_COMMAND="$1"
        else
          lum::fn::alias lum::help "$1" 0 "$list"
        fi
        ((added++))
        shift
      ;;
    esac
  done

  if [ $added -eq 0 ]; then
    ## Use defaults with a custom list.
    lum::help::register -l "$list" help --help
  fi
}

#$>
# Return the width of the terminal
lum::help::width() {
  stty size | cut -d' ' -f2
}

#$>
# Return the height of the terminal
lum::help::height() {
  stty size | cut -d' ' -f1
}

#$>
# A pre-canned message to show more information.
# In order to use it, set the ``LUM_HELP_COMMAND`` variable.
# See $see(lum::help::register); for a shortcut.
lum::help::moreinfo() {
  local vc="${LUM_THEME[help.value]}"
  local ac="${LUM_THEME[help.arg]}"
  local sc="${LUM_THEME[help.syntax]}"
  local ec="${LUM_THEME[end]}"

  echo "For command help info: $vc$LUM_HELP_COMMAND$ec ${sc}<${ac}command${sc}>$ec"
}
