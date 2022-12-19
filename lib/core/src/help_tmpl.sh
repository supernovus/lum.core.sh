#$< lum::core /help_tmpl
# Template engine for the help system

lum::var -P LUM_HELP_ \
  -i TMPL_INIT = 0 \
  -A DEFS THM \
  -A= FMT_HL \
     b = bold \
     h = header \
     i = item \
     p = param \
     a = arg \
     o = opt \
     e = '!' \
     s = syntax \
     v = value \
     -

lum::fn lum::help::def 0 -h 0 more
#$ <<name>> <<type>> <<handler>> `{...}`
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
#           The first character is the mandatory type code.
#           Additional characters are optional type modifiers,
#           and will be parsed in the order specified.
#
# ((handler))   The function that will process this feature.
#           Will have access to a ``tmplOptions`` local var with info
#           about the def, and any options and/or data associated with it.
#
#$line(See also);
# $see(,type); → The ((type)) values, and additional args.
# $see(,opts); → The ((tmplOptions)) available to handlers.
#
lum::help::def() {
  [ $# -lt 3 ] && lum::help::usage
  local -n DEF="LUM_HELP_DEFS"
  local dname="$1"
  shift
  DEF[$dname]="$@"
}

#$ lum::help::def,type - Help template handler types
#
# ``M``            Match a RegExp, assign value to local ``tmplText`` var.
#                Def args: <<regexp>> [[data...]]
#                  If ((data)) args are passed, they'll be available as a
#                  quoted string via the ``tmplOptions[data]`` variable.
#                Handler args: <<matches...>> 
#                No modifiers.
#
# ``P``            Pipe help text to ``STDIN``, replace with ``STDOUT``.
#                Def args: [[moreopts=0]] [[data...]]
#                  ((moredata)) if non-zero can be the name of a ``-A`` var
#                  to be merged into the ``tmplOptions`` local var.
#                No handler args unless added with modifiers.
#                Modifiers:
#                  ``-`` → Add ``tmplOptions`` var name to handler args.
#                  ``+`` → Add ((data)) values to handler args.
#
# ``p``            Pass help text, replace with ``STDOUT``.
#                Def args and modifiers are same as ``P``.
#                Handler args: <<helptext>>
#
#: lum::help::def,type

#$ lum::help::def,opts - Help template handler options
#
# The $v(tmplOptions) var contains a bunch of information
# about the template. 
#
# TODO: document pre-defined keys.
#
#: lum::help::def,opts

#$>
# Initialize the help template variables.
# Must be called before ``lum::help::tmpl``!
lum::help::tmpl--init() {
  ## Set up the theme
  LUM_HELP_THM[;]="${LUM_THEME[end]}"
  LUM_HELP_THM[!]="${LUM_THEME[error]}"
  LUM_HELP_THM[:]="${LUM_THEME[help.syntax]}"
  local tk hk
  for tk in "${!LUM_THEME[@]}"; do
    if lum::str::startsWith "$tk" 'help.'; then
      hk="${tk#help.}"
      LUM_HELP_THM[$hk]="${LUM_THEME[$tk]}"
    fi
  done

  ## Set up the default template feature definitions.
  local LHT=lum::help::tmpl
  lum::help::def arg M $LHT::arg '(.*?)<<(\w+)(\.\.\.)?>>(.*)'
  lum::help::def opt M $LHT::opt '(.*?)\[\[(\w+)(\.\.\.)?(=)?(\S+)?\]\](.*)'
  lum::help::def param M $LHT::hl '(.*?)\(\((.*?)\)\)(.*?)'
  lum::help::def value M $LHT::hl '(.*?)``(.*?)``(.*)' "'"
  lum::help::def syntax M $LHT::code '(.*?)`\{(.*?)\}`(.*)'
  lum::help::def fmt-pre M $LHT::fmt '(.*?)\$(\w+)\((.*?)\);(.*)'
  lum::help::def fmt-end M $LHT::fmt '(.*?)\$(\w+)\{(.*?)\};(.*)'

  ## Mark this as done
  LUM_HELP_TMPL_INIT=1
}

lum::fn lum::help::tmpl 4 -h 0 more -h fmt more
#$ - Default help template defs
#
# $b(modes  name       syntax        example(s));
#
# [+++] ``fmt-pre``   `{$\vfn\:(\vargs\:)\ ;}`   `{--}`
# [+--] ``value``     `{`\ `\vvalue\:`\ `}`     ``value``
# [+--] ``param``     `{(\ (\vparam\:)\ )}`     ((param))
# [-+-] ``arg``       `{<\ <\vargument\:>\ >}`  <<arg>> <<args...>>
# [-+-] ``opt``       `{[\ [\voption\:]\ ]}`    [[opt]] [[opt=def]] [[opts...]]
# [++-] ``syntax``    `{`\:{\vsyntax\:}\:`}`   `{--}`
# [++-] ``fmt-end``   `{$\vfn\:{\vargs\:}\ ;}`   `{--}`
#
# [012] ← Each column represents a help mode.
#         ``+`` = Supported by default in that mode.
#         ``-`` = Not supported by default.
#         ``0`` = ``default``
#         ``1`` = ``usage``
#         ``2`` = ``summary``
#
# Extra help group ``more`` includes ALL the defs, in the order shown.
#
# See $see(,fmt); for info on the ``fmt-*`` defs.
# See $see(,syntax); for info on the ``syntax`` formatting.
#
lum::help::tmpl() {
  local -n tmplDefs="$1"
  local helpMode="$2" fnName="$3" subName="$4"
  local tmplText="$(cat -)" dn type fn re
  local -A tmplOptions
  local -n TC="LUM_HELP_THM"

  for dn in "${tmplDefs[@]}"; do
    tmplOptions[class]="$dn"
    local -a def=(${LUM_HELP_DEFS[$dn]}) # No quotes; space delimited def.
    local type="${def[0]}"
    tmplOptions[type]="$type"
    local fn="${def[1]}"
    
    case "$type" in
      M*)
        local tmplRegExp="${def[2]}"
        tmplOptions[re]="$tmplRegExp"
        tmplOptions[data]="${def[@]:3}"
        while [[ $tmplText =~ $tmplRegExp ]]; do
          $fn "${BASH_REMATCH[@]}"
        done
      ;;
      P*|p*)
        local moreOpts="${def[2]:-0}"
        local -a moreArgs=()
        local -i typeLen="${#type}"

        tmplOptions[data]="${def[@]:3}"
        [ "$moreOpts" != "0" ] && lum::var::merge tmplOptions $moreOpts

        if [ $typeLen -gt 1 ]; then
          local -i typeMod
          for (( typeMod=1; typeMod<$typeLen; typeMod++ )); do
            case "${type:$typeMod:1}" in
              '-')
                moreArgs+=(tmplOptions)
              ;;
              '+')
                moreArgs+=("${def[@]:3}")
              ;;
            esac
          done
        fi
        
        [ "${type:0:1}" = "P" ] \
          && tmplText="$(echo "$tmplText" | $fn "${moreArgs[@]}")" \
          || tmplText="$($fn "$tmplText" "${moreArgs[@]}")"
      ;;
      *)
        lum::err "Unhandled type '$type' in a template def '$dn'"
      ;;
    esac
    shift
  done

  echo "$tmplText"
}

lum::help::tmpl::arg() {
  local before="$2"
  local after="$5"
  local arg="$3"
  local rep="$4"

  local param="${TC[:]}<${TC[arg]}$arg${TC[:]}"
  [ -n "$rep" ] && param+="$rep"
  param+=">${TC[;]}"

  tmplText="$before$param$after"
}

lum::help::tmpl::opt() {
  local before="$2"
  local after="$7"
  local arg="$3"
  local rep="$4"
  local eq="$5"
  local def="$6"

  param="${TC[:]}[${TC[opt]}$arg${TC[:]}"
  [ "$eq" = "=" -a -n "$def" ] && param+="$eq${TC[def]}$def${TC[:]}"
  [ -n "$rep" ] && param+="$rep"
  param+="]${TC[;]}"

  tmplText="$before$param$after"
}

lum::help::tmpl::hl() {
  local col="${tmplOptions[class]}"
  local d="${tmplOptions[data]}"
  local before="$2"
  local after="$4"
  local arg="$3"
  local param="$d${TC[$col]}$arg${TC[;]}$d"
  tmplText="$before$param$after"
}

lum::help::tmpl::code() {
  local before="$2"
  local after="$4"
  local arg="\:$3\;"
  local repValue
  lum::help::tmpl::fmt::_ "$arg"
  tmplText="$before$repValue$after"
}

lum::help::tmpl::fmt() {
  local before="$2"
  local after="$5"
  local fid="$3"
  local arg="$4"

  local repValue

  local cid="${LUM_HELP_FMT_HL[$fid]}"
  local fname="lum::help::tmpl::fmt::$fid"

  #echo "fmt(${tmplOptions[class]}) fid=$fid; arg=$arg; cid=$cid; fname=$fname;" >&2

  if [ -n "$cid" ]; then
    ## Our quick colour aliases are top priority.
    repValue="${TC[$cid]}$arg${TC[;]}"
  elif lum::fn::is "$fname"; then
    ## Followed by actual formatting functions.
    $fname "$arg"
  elif [ -n "${TC[$fid]}" ]; then
    ## Finally fall back to the local theme colours.
    repValue="${TC[$fid]}$arg${TC[;]}"
  else
    ## Nothing matched? Well that's not right.
    lum::warn "invalid fmt '$fid'"
  fi

  tmplText="$before$repValue$after"
}

lum::help::tmpl::fmt::var() {
  repValue="${!1}"
}

lum::help::tmpl::fmt::bool() {
  local -a boolOpts=($1)
  local varname="${boolOpts[0]}"
  local onval="${boolOpts[1]:-on}"
  local offval="${boolOpts[2]:-off}"
  [ "${!varname}" = 0 ] && repValue="$offval" || repValue="$onval"
}

lum::help::tmpl::fmt::pad() {
  repValue="$(lum::str::pad $1)"
}

lum::help::tmpl::fmt::X() {
  local -a xo=($@)
  local -i xr="${xo[0]:-1}"
  local xv="${xo[1]:- }"
  repValue="$(lum::str::repeat "$xv" $xr)"
}

lum::help::tmpl::fmt::line() {
  local -i width=$lineWidth
  local title
  local wre='(\d+) (.*)'

  if [ -n "$1" ]; then
    if [[ $1 =~ $wre ]]; then
      width="${BASH_REMATCH[1]}"
      title="${BASH_REMATCH[2]}"
    else
      title="$1"
    fi
  fi

  if [ -z "$title" ]; then
    repValue="$(lum::str::repeat "─" $width)"
  else
    repValue="$(lum::str::pad -c "─" "$width" "─($title)")"
  fi
}

lum::help::tmpl::fmt::see() {
  local -a seeOpts=($1)
  local link="${seeOpts[0]}"
  local -i pad="${seeOpts[1]:-0}"
  [ "${link:0:1}" = ',' ] && link="${helpOptions[root]}$link"
  [ $pad -gt 0 ] && link="$(lum::str::pad "$pad" "$link")"
  repValue="${TC[item]}$link${TC[;]}"
}

lum::help::tmpl::fmt::_() {
  local fmtCodeRegExp='\\([^.])' cc tc
  repValue="$1"

  while [[ $repValue =~ $fmtCodeRegExp ]]; do
    cc="${BASH_REMATCH[1]}"
    tc="${LUM_HELP_FMT_HL[$cc]}"
    [ -z "$tc" ] && tc="$cc"
    cc="${TC[$tc]}"
    repValue="${repValue//"${BASH_REMATCH[0]}"/"$cc"}"
  done

  repValue="${repValue//\\\./\\}"
}

#$ lum::help::tmpl,fmt - Formatting Functions
#
# $i(*); Colour-only codes: $b(b); $h(h); $i(i); $p(p); $a(a); $o(o); $e(e); $s(s); $v(v);.
# $i(*); `{$\ spc(\vlen\:)\ ;}` Insert ((len)) number of spaces (default ``1``).
# $i(*); `{$\ pad(\vlen text...\:)\ ;}` will pad the text with spaces.
# $i(*); `{$\ var(\vvarname\:)\ ;}` will display the ((varname)) variable.
# $i(*); `{$\ bool(\vvarname on? off?\:)\ ;}` show ((off)) if ((name)) is ``0``, or ((on)) otherwise.
#    ((on)) default value is ``on``, ((off)) default value is ``off``.
# $i(*); `{$\ see(\vlink pad?\:)\ ;}` will display a link to another help item.
#    If the ((link)) starts with a ``,`` it is a sub-topic of the current topic.
#    ((pad))        → If specified, pad the end of the string to this length.
# $i(*); `{$\ line(\vwidth? caption?\:)\ ;}` will draw a line.
#    ((width))      → If specified the line will be this long.
#                 Otherwise it will fill the width of the terminal.
#    ((caption))    → If specified, a caption will be embedded in the line.
#    You can specify either one without specifying the other.
#    However to specify BOTH, they MUST be in the order shown.
#$line();
# $i(*); `{$\ _(\vformat text\:)\ ;}` see $see(,syntax);
#
#: lum::help::tmpl,fmt

#$ lum::help::tmpl,syntax - Advanced Syntax
#
# When advanced formatting is required, there are two built-in syntaxes:
#
# $i(*); `{`\:{\vblock of text\:}\:`}`  → A syntax block, adds $v(\:); prefix and $v(\;); suffix.
# $i(*); `{$\ _(\vblock of text\:)\ ;}` → A format block, no prefix or suffix added.
#
# Special escape codes are used to apply additional formatting:
#
# $i(*); Set colours: $b(\b); $h(\h); $i(\i); $p(\p); $a(\a); $o(\o); $e(\e \!); $s(\s \:); $v(\v);
# $i(*); End colours: \;
# $i(*); Show \ char: \.
#
# If an unrecognized $v(\X); code is found, it will simply be stripped.
# This can be used to escape documentation syntax.
#
#: lum::help::tmpl,syntax
