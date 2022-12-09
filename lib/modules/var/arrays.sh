#$< lum::var::arrays
# More var functions dealing with arrays

lum::fn lum::var::rmFrom
#$ [[options]] <<varname>> <<value...>>
#
# Remove value(s) from an array (-a) variable
# Does NOT work with associative array (-A) variables!
#
# ((varname))     The name of the array variable.
# ((value))       One or more values to be removed.
#
# ((options))     Named options for advanced features:
#
# ``-i``        Reindex the array (if you care about consecutive index keys).
# ``-r``        ((value)) is a RegExp to match rather than a single value.
#
lum::var::rmFrom() {
  local -i reindex=0 isRE=0

  while [ $# -gt 0 ]; do
    case "$1" in 
      -i)
        reindex=1
        shift
      ;;
      -r)
        isRE=1
        shift
      ;;
      *)
        break
      ;;
    esac
  done

  [ $# -lt 2 ] && lum::help::usage

  [ "$(lum::var::type "$1")" != "-a" ] && lum::help::usage
  local findVal curVal curKey

  local -n theArray="$1"
  shift

  while [ $# -gt 0 ]; do
    findVal="$1"
    if [ $reindex -eq 1 ]; then
      local -a newArray=()
      for curVal in "${theArray[@]}"; do
        if [ $isRE -eq 1 ]; then
          [[ $curVal =~ $findVal ]] || newArray+=("$curVal")
        else
          [ "$curVal" = "$findVal" ] || newArray+=("$curVal")
        fi
      done
      theArray=("${newArray[@]}")
    else
      for curKey in "${!theArray[@]}"; do
        curVal="${theArray[$curKey]}"
        if [ $isRE -eq 1 ]; then
          [[ $curVal =~ $findVal ]] && unset "theArray[$curKey]"
        else
          [ "$curVal" = "$findVal" ] && unset "theArray[$curKey]"
        fi
      done
    fi
    shift
  done
}
