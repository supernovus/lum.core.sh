#@lib: lum::tmpl
#@desc: A cheap template engine

declare -gA LUM_TMPL_VARS

lum::fn lum::tmpl
#$ [[flags=0]] [[filename=STDIN]]
#
# Parse a file (or ``STDIN``) for template values.
#
# Template statements are enclosed in `{{\\{ }}}` brackets.
#
lum::tmpl() {
  local _flags="${1:-0}" _filename="${2:--}" 
  local _pattern="(.*?)\{\{\s*(.*?)\}\}(.*)" 
  local _text="$(cat $_filename)" _k _v _e
  local -n TMPL=LUM_TMPL_VARS

  for _k in "${!TMPL[@]}"; do
    _v="${TMPL[$_k]}"
    local $_k="$_v"
  done
  unset _k _v

  while [[ $_text =~ $_pattern ]]; do
		_e="${BASH_REMATCH[2]}"
		[ "${_e:0:1}" = '$' ] && _e="echo $_e"
		_e="$(eval $_e)"
    _text="${BASH_REMATCH[1]}${_e}${BASH_REMATCH[3]}"
  done

  echo "$_text"
}

lum::fn lum::tmpl::set
#$ <<key1>> <<val1>> `{...}`
#
# Set template variables.
#
# Can specify any number of key/value pairs.
# Just make sure they're matched.
#
lum::tmpl::set() {
  [ $# -lt 2 ] && lum::help::usage
  while [ $# -gt 0 ]; do
    LUM_TMPL_VARS[$1]="$2"
    shift 
    shift
  done
}

lum::fn lum::tmpl::reset 
#$ `{--}`
#
# Reset template variables to initial state.
#
lum::tmpl::reset() {
  LUM_TMPL_VARS=()
}
