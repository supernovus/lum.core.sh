## core lum::var

[ -z "$LUM_NEED_ERRCODE" ] && LUM_NEED_ERRCODE=199

lum::fn lum::var::is
#$ <<varname>>
#
# Test if a global variable IS set.
#
lum::var::is() {
  [ -n "${!1}" ]
}

lum::fn lum::var::not
#$ <<varname>>
#
# Test if a global variable is NOT set.
#
lum::var::not() {
  [ -z "${!1}" ]
}

lum::fn lum::var::need
#$ <<varname>>
#
# If a global variable is NOT set, die with an error.
#
lum::var::need() {
  if lum::var::not "$1"; then 
    echo "Missing '$1' variable" >&2
    exit $LUM_NEED_ERRCODE
  fi
}

lum::fn lum::var::has
#$ <<varname>> <<want>>
#
# See if a global array variable contains a value.
#
# ((varname))    The name of the global array variable.
#
# ((want))       The value we are looking for.
#
lum::var::has() {
  [ $# -lt 2 ] && lum::help::usage
  local item want="$2"
  local -n array="$1"
  for item in "${array[@]}"; do
    [[ "$item" == "$want" ]] && return 0
  done
  return 1
}
