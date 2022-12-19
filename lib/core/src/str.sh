#$< lum::core /str
# String utilities

lum::fn lum::str::pad 0 -h 0 more
#$ [[opts...]] <<len>> <<string...>>
#
# Pad a string to a specified length.
#
# ((len))     → The length the final string should be.
# ((string))  → One or more strings to concat.
# ((opts))    → Options:
#  $v(-f);         → Add the padding to the front rather than the end.
#  $v(-c); <<char>>  → Use ((char)) for padding instead of `{space}`.
#
lum::str::pad() {
  local char fmt='%-'
  while [ $# -gt 0 ]; do
    case "$1" in
      -c)
        char="$2"
        shift 2
      ;;
      -f)
        fmt='%'
        shift
      ;;
      *)
        break;
      ;;
    esac
  done

  [ $# -lt 2 ] && lum::help::usage
  local -i len=$1
  fmt+="${len}s"
  shift

  local string="$@"
  local padded="$(printf "$fmt" "$string")"

  if [ -n "$char" ]; then 
    if [ -z "$string" ]; then
      padded="${padded// /$char}"
    else
      local padding="${padded/$string}"
      padding="${padding// /$char}"
      [ "${fmt:1:1}" = '-' ] \
        && padded="$string$padding" \
        || padded="$padding$string"
    fi
  fi
  
  echo "$padded"
}

lum::fn lum::str::repeat
#$ <<string>> <<times>>
#
# Repeat a specific string multiple times.
#
# ((string))    → The string we want to repeat.
# ((times))     → How many times to repeat it.
#
lum::str::repeat() {
  ## Yes, we could just do lum::str::pad -c "$string" "$times" ''
  ## but this version doesn't require $(subshells) or ${rep/lace/ments}
  local -i c=0 times="$2"
  local in="$1" out
  for ((c=0; c<$times; c++ ))
  do
    out+="$in"
  done
  echo "$out"
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
