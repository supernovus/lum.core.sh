## lum::use::from extension

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::lib lum::use::from $LUM_CORE

lum::fn lum::use::from
#$ <<path>>
#
# Look for special files indicating which libraries to load.
#
# ((path))      The path to the control files.
#
# Two types of control files are supported:
#
# ``.lib``    The basename of these files are the names of the libraries.
# ``.cnf``    The basename of these files are the name sof the config files.
#
lum::use::from() {
  [ $# -lt 1 ] && lum::help::usage
  local libName
  if [ -d "$1" ]; then
    for libName in $1/*.lib; do
      [ -e "$libName" ] || continue
      libName=$(basename $libName .lib)
      lum::use $libName
    done

    for libName in $1/*.cnf; do
      [ -e "$libName" ] || continue
      libName=$(basename $libName .cnf)
      lum::use --opt --conf $libName
    done
  fi
}
