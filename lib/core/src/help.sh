#@lib: lum::core /help
#@desc: A help system

[ -z "$LUM_USAGE_TITLE" ] && LUM_USAGE_TITLE="usage: "
[ -z "$LUM_USAGE_MORE_INFO" ] && LUM_USAGE_MORE_INFO=1
[ -z "$LUM_USAGE_STACK" ] && LUM_USAGE_STACK=0
[ -z "$LUM_WARN_LVL" ] && LUM_WARN_LVL=-1
[ -z "$LUM_ERR_LVL" ] && LUM_ERR_LVL=2

declare -gr LUM_HELP_START_FN="lum::fn"
declare -gr LUM_HELP_START_MARKER="#$"
declare -gr LUM_HELP_END_MARKER="#:"

declare -gA LUM_THEME

lum::fn lum::help
#$ <<name>> [[mode=0]]
#
# Show help information for a function.
#
# ((name))      Name of the function (e.g. ``lum::help``)
#           If set to ``0``, uses the name of the calling function.
#
# ((mode))      What help text we want to return:
#           ``0`` = Return the entire help text.
#           ``1`` = Return only the usage line.
#           ``2`` = Return only the summary line.
#
lum::help() {
  [ $# -lt 1 ] && lum::help::usage
  local prefind  dName fName="${1:-0}" S
  local -i want=${2:-0}
  local err="${LUM_THEME[error]}"
  local end="${LUM_THEME[end]}"
  local -i SF=1 EF=2 US=4 FS=0

  [ "$fName" = "0" ] && fName="${FUNCNAME[1]}"

  [ -n "${LUM_ALIAS_FN[$fName]}" ] && fName="${LUM_ALIAS_FN[$fName]}"
  
  local -i flags="${LUM_FN_FLAGS[$fName]:-0}"
  lum::flag::is $flags $SF && FS=1

  local usageTags _tk="$want|$fName" _ak="$want|*"
  local wantTags="${LUM_FN_HELP_TAGS[$_tk]:-${LUM_FN_HELP_TAGS[$_ak]}}"

  if [ "$want" = 1 ]; then 
    usageTags="$wantTags" 
  else 
    _tk="1|$fName"
    _ak="1|*"
    usageTags="${LUM_FN_HELP_TAGS[$_tk]:-${LUM_FN_HELP_TAGS[$_ak]}}"
  fi

  if [ -n "${LUM_FN_ALIAS[$fName]}" ]; then
    dName="${LUM_FN_ALIAS[$fName]} "
  elif [ $FS -eq 0 ]; then
    dName="$fName "
  fi

  if [ $FS -eq 1 ]; then
    prefind="${LUM_HELP_START_MARKER} $fName"
  else
    prefind="$LUM_HELP_START_FN $fName"
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

  [ $FS -eq 0 ] && ((S++))

  if [ "$want" = 2 ]; then
    local start
    if lum::flag::is $flags $US; then 
      start="$LUM_HELP_START_MARKER"
    else
      start='#'
      ((S+=2))
    fi
    sed -n "${S}{s/^${start}\s*//;p}" "$LFILE" | lum::help::tmpl $wantTags
    return 0
  fi

  local output="$(sed -n "${S}{s/$LUM_HELP_START_MARKER\s*/$dName/;p}" "$LFILE")"
  [ $FS -eq 1 -a -n "$dName" ] && output="${output/$fName}"
  echo "$output" | lum::help::tmpl $usageTags
  [ "$want" = 1 ] && return 0

  ((S++))

  local suffind E
  if lum::flag::is $flags $EF; then 
    suffind="${LUM_HELP_END_MARKER} $fName"
  else 
    suffind="${fName}()"
  fi
  E=$(grep -nm 1 "^$suffind" "$LFILE" | cut -d: -f1)

  if [ -n "$E" ]; then
    ((E--))
    sed -n "${S},${E}{s/^#//;p}" "$LFILE" | lum::help::tmpl $wantTags
  else
    output=""
    local line
    while true; do
      line="$(sed -n "${S}p" "$LFILE")"
      [ "${line:0:1}" != "#" ] && break
      output+="${line:1}\n"
      ((S++))
    done
    echo -e "$output" | lum::help::tmpl $wantTags
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
  local S=${1:-1} E=${#BASH_SOURCE[@]} L
  local mc="${LUM_THEME[diag.func]}"
  local fc="${LUM_THEME[diag.file]}"
  local lc="${LUM_THEME[diag.line]}"
  local ec="${LUM_THEME[end]}"
  local fn sf ln
  ((E--))
  for L in $(seq $S $E);
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
  local -i DL="${2:-$LUM_WARN_LVL}"
  echo -e "$1" >&2
  [ $DL -gt -1 ] && lum::help::diag $DL >&2
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
  local -i errCode="${2:-1}" DL="${3:-$LUM_ERR_LVL}"
  echo -e "$1" >&2
  [ $DL -gt -1 ] && lum::help::diag $DL >&2
  [ "$errCode" -gt -1 ] && exit $errCode
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
  local fName want errCode="${2:-100}" DL

  if [ -z "$1" -o "$1" = "0" ]; then
    fName="${FUNCNAME[1]}"
    DL=2
  else
    fName="$1"
    DL=1
  fi

  want="$(lum::help $fName 1)"
  if [ -n "$want" ]; then
    [ "$LUM_USAGE_TITLE" != "0" ] && want="${LUM_USAGE_TITLE}$want"
    echo "$want" >&2
    if [ "$LUM_USAGE_STACK" != "0" ]; then 
      lum::help::diag $DL >&2
    elif [ "$LUM_USAGE_MORE_INFO" != "0" ]; then
      lum::help::moreinfo >&2
    fi
  fi
  [ $errCode -gt -1 ] && exit $errCode
}

lum::fn lum::help::tmpl
#$ <<tags>>
#
# Parse ``STDIN`` for help document tags.
# Uses loaded theme colours when supported by the terminal.
#
# ((tags))  Bitwise flags for what tags to allow.
#       See ``lum::help::tmpl.tags`` for details.
# 
lum::help::tmpl() {
  local tags="${1:-0}"
  local SYN=1 ARG=2 VAL=4 VAR=8 EXT=16

  local argPattern='(.*?)<<(\w+)(\.\.\.)?>>(.*)'
  local optPattern='(.*?)\[\[(\w+)(=)?(\w+)?(\.\.\.)?\]\](.*)'
  local parPattern='(.*?)\(\((.*?)\)\)(.*?)'
  local synPattern='(.*?)`\{(.*?)\}`(.*)'
  local valPattern='(.*?)``(.*?)``(.*)'
  local varPattern='(.*?)\$\{(\w+)\}(.*)'
  local extPattern='(.*?)@([<>])(\S+?);(.*)'
  local padPattern='(.*?)@(\d+)\((.*?)\)(.*)'
  local bldPattern='(.*?)\*\*(.*?)\*\*(.*)'
  local escPattern='(.*?)\\\\(.*)'
  local bsePattern='(.*?)\\\/\/\\(.*)'

  local text="$(cat -)" before after arg eq def param rep bs='\\'

  local bc="${LUM_THEME[help.bold]}"
  local sc="${LUM_THEME[help.syntax]}"
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

  if lum::flag::is $tags $VAR; then
    while [[ $text =~ $varPattern ]]; do
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[3]}"
      param="${!BASH_REMATCH[2]}"
      text="$before$param$after"
    done
  fi

  if lum::flag::is $tags $ARG; then
    while [[ $text =~ $argPattern ]]; do 
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[4]}"
      arg="${BASH_REMATCH[2]}"
      rep="${BASH_REMATCH[3]}"
      param="$sc<$ac$arg$sc"
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
      param="$sc[$oc$arg$sc"
      [ "$eq" = "=" -a -n "$def" ] && param="$param$eq$dc$def$sc"
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
      param="$sc$arg$ec"
      text="$before$param$after"
    done

    while [[ $text =~ $bldPattern ]]; do 
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

    while [[ $text =~ $bsePattern ]]; do
      before="${BASH_REMATCH[1]}"
      after="${BASH_REMATCH[2]}"
      text="$before$bs$after"
    done
  fi

  echo "$text"
}

lum::fn lum::help::tmpl.tags 2
#$ `{int}`
#
# The ((flags)) argument of ``lum::help::tmpl``
#
# ``1``  = Enable `{`\\{ Misc syntax }\\`}`, `{*\\* bold text *\\*}`, 
#        and `{@\\int(pad text)}` tags. Enables `{\//\}` escapes.
# ``2``  = Enable `{<\\< argument >\\>}` and `{[\\[ option ]\\]}` tags.
# ``4``  = Enable `{(\\( parameter )\\)}` and `{`\\` value `\\`}` tags.
# ``8``  = Enable `{$\\{variable}\\}` tags.
# ``16`` = Enable `{@\\>pipeCmd;}` and `{@\\<passCmd;}` extension tags.
#        See ``lum::help::tmpl.exts`` for details.
#
#: lum::help::tmpl.tags

lum::fn lum::help::tmpl.exts 2
#$ `{...}`
#
# Extension tags for ``lum::help::tmpl``
#
# **@\\>cmd;**  Template is piped (``STDIN``) to the ``cmd`` function,
#         which is passed ((tags)) as its only argument.
#
# **@\\<cmd;**  The ``cmd`` function is passed ((tags)) and then the template
#         text as two separate arguments.
#
# In both cases, the output (``STDOUT``) will be the new template text.
#
#: lum::help::tmpl.exts

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

lum::fn lum::help::moreinfo
#$
#
# Show a help usage summary
#
lum::help::moreinfo() {
  local vc="${LUM_THEME[help.value]}"
  local ac="${LUM_THEME[help.arg]}"
  local sc="${LUM_THEME[help.syntax]}"
  local ec="${LUM_THEME[end]}"

  echo "For command help info: ${vc}help$ec ${sc}<${ac}command${sc}>$ec"
}
