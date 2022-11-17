## Simple argument handling stuff

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::lib lum::args $LUM_CORE

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
