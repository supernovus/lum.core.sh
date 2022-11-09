## core lum::lib

declare -gA LUM_LIB_FILES
declare -gA LUM_LIB_VER
declare -gA LUM_FILE_LIBS

lum::fn lum::lib
#$ <<libname>> <<version>>
#
# Register an extension library.
#
lum::lib()
{
  [ $# -lt 2 ] && lum::help::usage
  local caller="${BASH_SOURCE[1]}" name="$1" ver="$2"
 
  if [ -n "${LUM_LIB_VER[$name]}" ]; then
    echo "library '$name' already registered"
    return 1
  fi

  LUM_LIB_VER[$name]=$ver
  LUM_LIB_FILES[$name]="$caller"
  LUM_FILE_LIBS[$caller]="$name"
}
