#@lib: lum::core /str
#@desc: String utilities

lum::fn lum::str::pad
#$ <<len>> <<string...>>
#
# Pad a string to a specified length.
#
# ((len))     The length the final string should be.
#
# ((string))  One or more strings to concat.
#
lum::str::pad() {
  [ $# -lt 2 ] && lum::help::usage
  local len=$1
  shift
  printf "%-${len}s" "$@"
}

lum::fn lum::str::startsWith
#$ <<string>> <<prefix>>
#
# Test for a prefix in a string.
#
lum::str::startsWith() {
  case "$1" in 
    "$2"*) return 0 ;;
    *) return 1 ;;
  esac
}

lum::fn lum::str::endsWith
#$ <<string>> <<suffix>>
#
# Test for a suffix in a string.
#
lum::str::endsWith() {
  case "$1" in 
    *"$2") return 0 ;;
    *) return 1 ;;
  esac
}

lum::fn lum::str::contains
#$ <<string>> <<substr>>
#
# Test for a sub-string in a string.
#
lum::str::contains() {
  case "$1" in 
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}
