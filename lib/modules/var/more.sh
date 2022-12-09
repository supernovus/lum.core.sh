#$< lum::var::more
# More var functions adding to those in the core.

lum::fn lum::var::need
#$ <<varname>>
#
# If a variable is NOT set, die with an error.
#
lum::var::need() {
  if ! lum::var::is "$1"; then 
    lum::err "Missing '$1' variable" $LUM_NEED_ERRCODE 
  fi
}

lum::fn lum::var::sort
#$ <<invar>> <<outvar>> [[options...]]
#
# Sort an array
#
# ((invar))        The name of the array variable to sort.
# ((outvar))       The name of the target array variable.
# ((options))      Any options for the ``sort`` command.
#
lum::var::sort() {
  [ $# -lt 2 ] && lum::help::usage
  local -n invar="$1"
  local -n outvar="$2"
  shift 2
  local sortOpts="$@"
  local IFS=$'\n'
  outvar=($(sort $sortOpts <<<"${invar[*]}"))
}
