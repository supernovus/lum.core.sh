#@lib: lum::core /help_tmpl
#@desc: Template engine for the help system

lum::var -P LUM_HELP_ -A DEFS THM \
  DEFS_FMT_PRE DEFS_FMT_END FMT_VARS \
  -i TMPL_INIT=0

lum::fn lum::help::def
#$ <<name>> <<type>> `{...}`
#
# Define a help template feature
#
# Due to limitations in the storage format, none of the arguments passed to
# this function may contain embedded spaces. 
#
# ((name))      A unique name for the def.
#           If for a type with a tag, this will be the tag name.
#
# ((type))      A code determining the handler behaviour.
#
# See also:
#
# ``lum::help::def.type``  → The ((type)) values, and additional args.
# ``lum::help::def.opts``  → The ((optsvar)) arg passed to handlers.
#
lum::help::def() {
  [ $# -lt 3 ] && lum::help::usage
  local dname="$1" type="$2"
  shift 2

  case "$type" in
    P|p|M)
      local -n DEF="LUM_HELP_DEFS"
      DEF[$dname]="$type $@"
    ;;
    m)
      [ $# -lt 2 ] && lum::help::usage
      local fname="$1" vname="$2"
      shift 2
      declare -gA "$vname"
      local -n DEF="$vname"
      DEF[$dname]="$type $fname $@"
    ;;
    *)
      lum::help::usage
    ;;
  esac

}

lum::fn lum::help::def.type 6 -t 0 7
#$ - Help template handler types
#
# ``P``            Pipe help text to ``STDIN``, replace with ``STDOUT``.
#                Def args: <<handler>> [[metadata...]]
#                Handler args: <<optsvar>>
#
# ``p``            Pass help text, replace with ``STDOUT``.
#                Def args: <<handler>> [[metadata...]]
#                Handler args: <<helptext>> <<optsvar>>
#
# ``M``            Match a RegExp, replace text with ``STDOUT``.
#                Def args: <<handler>> <<regexp>> [[metadata...]]
#                Handler args: <<optsvar>> <<fullmatch>> [[submatches...]]
#
# ``m``            A sub-match handler called from a parent ``M`` handler.
#                Def args: <<handler>> <<defvar>> [[metadata...]]
#                Handler args: <<optsvar>> [[subvals...]]
#                The def is stored in the ((defvar)) global variable.
#
#: lum::help::def.type

lum::fn lum::help::def.opts 6 -t 0 7
#$ - Help template handler options
#
# Every handler function is passed an ((optsvar)) argument.
# This argument is the name of a local scope ``-A`` array variable that 
# contains options and metadata for the handler. TODO: document this further.
#
#: lum::help::def.opts

lum::help::tmpl--init() {
  ## Set up the theme
  LUM_HELP_THM[;]="${LUM_THEME[end]}"
  LUM_HELP_THM[!]="${LUM_THEME[error]}"
  LUM_HELP_THM[:]="${LUM_THEME[help.syntax]}"
  local tk hk
  for tk in "${!LUM_THEME}"; do
    if lum::str::startsWith "$tk" 'help.'; then
      hk="${tk#help.}"
      LUM_HELP_THM[$hk]="${LUM_THEME[$tk]}"
    fi
  done

  ## Set up the default template feature definitions.
  local LHT=lum::help::tmpl
  lum::help::def var M $LHT::var '(.*?)\$\{(\w+)\}(.*)'
  lum::help::def arg M $LHT::arg '(.*?)<<(\w+)(\.\.\.)?>>(.*)'
  lum::help::def opt M $LHT::opt '(.*?)\[\[(\w+)(=)?(\S+)?(\.\.\.)?\]\](.*)'
  lum::help::def param M $LHT::param '(.*?)\(\((.*?)\)\)(.*?)'
  lum::help::def val M $LHT::val '(.*?)``(.*?)``(.*)'
  lum::help::def syntax M $LHT::syntax '(.*?)`\{(.*?)\}`(.*)'

  local FPRE=LUM_HELP_DEFS_FMT_PRE FEND=LUM_HELP_DEFS_FMT_END FMTF=$LHT::fmt

  lum::help::def fmt-pre M $FMTF '(.*?)\$\.(\w+)\((.*?)\)(.*)' $FPRE
  lum::help::def fmt-end M $FMTF '(.*?)\$:(\w+)\((.*?)\)(.*)' $FEND

  lum::help::def 'esc' m $FMTF::esc $FPRE
  local -a FMT_FNS=(b head code val pad clr)
  local FF
  for FF in "${FMT_FNS[@]}"; do
    lum::help::def $FF m $FMTF::$FF $FPRE
    lum::help::def $FF m $FMTF::$FF $FEND
  done
  lum::help::def 'escaped' m $FMTF::escaped $FEND

  ## Mark this as done
  LUM_HELP_TMPL_INIT=1
}

lum::help::tmpl() {
  [ $LUM_HELP_TMPL_INIT -ne 1 ] && lum::help::tmpl--init

  local -n tmplDefs="$1"
  local text="$(cat -)" dn type fn re
  local -A tmplOptions
  local -n TC="LUM_HELP_THM"

  for dn in "${tmplDefs[@]}"; do
    tmplOptions[class]="$dn"
    local -a def=(${LUM_HELP_DEFS[$dn]}) # No quotes; space delimited def.
    local type="${def[0]}"
    tmplOptions[type]="$type"
    local fn="${def[1]}"
    case "$type" in
      P)
        tmplOptions[data]="${def[@]:2}"
        text="$(echo "$text" | $fn tmplOptions)"
      ;;
      p)
        tmplOptions[data]="${def[@]:2}"
        text="$($fn "$text" tmplOptions)"
      ;;
      M)
        local tmplRegExp="${def[2]}"
        tmplOptions[re]="$tmplRegExp"
        tmplOptions[data]="${def[@]:3}"
        while [[ $text =~ $tmplRegExp ]]; do
          text="$($fn tmplOptions "${BASH_REMATCH[@]}")"
        done
      ;;
      m)
        ## This type is called from a parent handler.
        continue
      ;;
      *)
        lum::err "Unhandled type '$type' in a template def"
      ;;
    esac
  done
}

lum::fn lum::help::tmpl::call
#$ <<defvar>> <<name>> <<optsvar>> [[args...]]
#
# Call a child template def
#
# ((defvar))      The name of the ``-A`` var with the defs.
# ((name))        The name of the child def you want to call.
# ((optsvar))     The name of the options variable.
#             If ``-``, uses the default lum::help::tmpl name.
# ((args))        Arguments to pass to the child after ((optsvar)). 
#
lum::help::tmpl::call() {
  [ $# -lt 3 ] && lum::help::usage
  local -n childDefs="$1"
  local childOptsVar="$3"
  [ -z "$childOptsVar" -o "$childOptsVar" = '-' ] && childOptsVar=tmplOptions
  local -n childOpts="$childOptsVar"
  childOpts[childClass]="$2"
  local -a childDef=(${childDefs[$2]}) # No quotes; space delimited def.
  childOpts[childType]="${childDef[0]}"
  local childFn="${childDef[1]}"
  shift 3
  $childFn childOpts "$@"
}

lum::help::tmpl::var() {
  local before="$3"
  local after="$5"
  local param="${!4}"
  echo "$before$param$after"
}

lum::help::tmpl::arg() {
  local before="$3"
  local after="$6"
  local arg="$4"
  local rep="$5"

  local param="${TC[:]}<${TC[arg]}$arg${TC[:]}"
  [ -n "$rep" ] && param+="$rep"
  param+=">${TC[;]}"

  echo "$before$param$after"
}

lum::help::tmpl::opt() {
  before="$3"
  after="$8"
  arg="$4"
  eq="$5"
  def="$6"
  rep="$7"

  param="${TC[:]}[${TC[arg]}$arg${TC[:]}"
  [ "$eq" = "=" -a -n "$def" ] && param+="$eq${TC[def]}$def${TC[:]}"
  [ -n "$rep" ] && param+="$rep"
  param+="]${TC[;]}"

  echo "$before$param$after"
}
