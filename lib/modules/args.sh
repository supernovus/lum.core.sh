#@lib: lum::args
#@desc: Argument related functions

lum::fn lum::args::has 
#$ <<want>> <<values...>>
#
# See if a list of arguments contains a value.
#
lum::args::has() {
  [ $# -lt 2 ] && lum::help::usage
  local item want="$1"
  shift 
  for item; do
    [[ "$item" == "$want" ]] && return 0
  done
  return 1
}
