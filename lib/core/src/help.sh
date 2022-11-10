## help def

[ -z "$LUM_USAGE_TITLE" ] && LUM_USAGE_TITLE="usage: "
[ -z "$LUM_USAGE_STACK" ] && LUM_USAGE_STACK=0

declare -gr LUM_HELP_START_MARKER="#$"
declare -gr LUM_HELP_END_MARKER="#:"
declare -gA LUM_THEME

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
  local prefind suffind dName sName fName="$1" S E output
  local -i want=${2:-0}
  local err="${LUM_THEME[error]}"
  local end="${LUM_THEME[end]}"
  local -i SF=1 EF=2 DF=4

  [ -n "${LUM_ALIAS_FN[$fName]}" ] && fName="${LUM_ALIAS_FN[$fName]}"
  
  local -i flags="${LUM_FN_FLAGS[$fName]:-0}" 
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
  elif lum::flag::not $flags 1; then
    dName="$fName "
  fi

  if lum::flag::is $flags $DF; then
    sName="$dName"
  else
    sName="$fName"
  fi

  if lum::flag::is $flags $SF; then
    prefind="${LUM_HELP_START_MARKER} $sName"
  else
    prefind="lum::fn $fName"
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
    sed -n "${S}{s/^#//;p}" "$LFILE" | lum::help::tmpl $wantTags
    return 0
  fi

  if [ "$want" = 0 ]; then
    if lum::flag::is $flags 2; then 
      suffind="${LUM_HELP_END_MARKER} $sName"
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
  sed -n "${S}{s/$LUM_HELP_START_MARKER\s*/$dName/;p}" "$LFILE" | lum::help::tmpl $usageTags
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
  local lc="${LUM_THEME[diag.line]}"
  local ec="${LUM_THEME[end]}"
  local fn sf ln
  ((E--))
  #echo ">> BASH_SOURCE=${BASH_SOURCE[@]}" >&2
  #echo ">> FUNCNAME=${FUNCNAME[@]}" >&2
  for L in $(seq $S $E);
  do
    fn="${FUNCNAME[$L]}"
    sf="${BASH_SOURCE[$L]}"
    ln="${BASH_LINENO[$L]}"
    echo " → $mc$fn$ec ($fc$sf$ec:$lc$ln$ec)"
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
