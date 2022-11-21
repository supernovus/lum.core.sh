#@lib: lum::core /flag
#@desc: Bitwise flag functions

lum::fn lum::flag::is
#$ <<bitvalue1>> <<bitvalue2>>
#
# Test for the presense of bitwise flags.
#
# Performs a bitwise AND against two values.
# Returns true if the value is NOT zero.
#
lum::flag::is() {
  [ $# -ne 2 ] && lum::help::usage
  local bitA=$1 bitB=$2 testVal
  testVal=$((bitA & bitB))
  [ $testVal -eq 0 ] && return 1
  return 0
}

lum::fn lum::flag::not
#$ <<bitvalue1>> <<bitvalue2>>
#
# Test for the absense of bitwise flags.
#
# Performs a bitwise AND against two values.
# Returns true if the value IS zero.
#
lum::flag::not() {
  [ $# -ne 2 ] && lum::help::usage
  local bitA=$1 bitB=$2 testVal
  testVal=$((bitA & bitB))
  [ $testVal -eq 0 ] && return 0
  return 1
}

lum::fn lum::flag::set
#$ <<bitvalues...>>
#
# Combine all arguments with a bitwise OR.
#
lum::flag::set() {
  [ $# -lt 1 ] && lum::help::usage
  local -i retval=0 testval
  while [ $# -gt 0 ]; do
    testval=$1
    shift
    ((retval |= testval))
  done
  echo $retval
}
