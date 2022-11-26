#@lib: lum::help::cli
#@desc: An advanced CLI help script for Lum.sh
#@desc: Not meant for use by anything other than lum-core/bin/help.sh

[ -n "$LUM_CORE_PKG_DIR" -a -d "$LUM_CORE_PKG_DIR" ] || lum::err "Not supported"

LUM_INST_PKG="$(dirname "$LUM_CORE_PKG_DIR")"
LUM_CORE_NAME="$(basename "$LUM_CORE_PKG_DIR")"

declare -gi LUM_INST_DEV=0
declare -ga LUM_PKG_ROOTS=("$LUM_INST_PKG")
declare -gr LUM_PKG_INST_CONF="$LUM_INST_PKG/lum-pkg/etc/installation.conf"

case "$LUM_CORE_NAME" in 
  lum-core)
    if [ -f "$LUM_PKG_INST_CONF" ]; then
      . "$LUM_PKG_INST_CONF"
      [ -n "$LUM_SITE_PKG" ] && LUM_PKG_ROOTS+=("$LUM_SITE_PKG")
    fi
  ;;
  core)
    LUM_INST_DEV=1
  ;;
  *)
    echo "invalid lum-core installation"
    exit 250
  ;;
esac

lum::fn lum::help::cli
#$ [[options...]] <<topic>>
#
# Look up a help topic
#
# ((options))      Named options to change behaviours.
#              See ``lum::help::cli.opts`` for details.
# ((topic))        The name of a function or help topic.
#
lum::help::cli() {
  lum::getopts lh

  lh::def P pkg '+' L lib '+' l list '?'
  lh::parse 1 "$@"

  local -n OPTS="$(lh::opts)"
  local -n ARGS="$(lh::args)"
  local -n PKGS="$(lh::+pkg)"
  local -n LIBS="$(lh::+lib)"

  local pkg lib inc

  for pkg in "${PKGS[@]}"; do
    lum::help::cli::+pkg "$pkg"
  done

  for lib in "${LIBS[@]}"; do
    lum::use "$lib"
  done

  if [ -n "${OPTS[list]}" ]; then
    pref="${OPTS[list]}"
    [ "$pref" = '-' ] && pref='lum::'
    lum::fn::list "$pref"
    exit
  fi

  #echo "LUM_PKG_ROOTS=${LUM_PKG_ROOTS[@]}"

  lum::help "$ARGS"
}

lum::help::cli::+pkg() {
  local pkg="${1/::/-}"
  local -i fatal="${2:-1}"

  [ $LUM_INST_DEV -eq 1 ] && pkg="${pkg/lum-/}"

  local pdir
  for pdir in "${LUM_PKG_ROOTS[@]}"; do
    if [ -d "$pdir/$pkg" -a -f "$pdir/$pkg/PACKAGE.conf" ]; then
      lum::help::cli::+pkg-conf "$pdir/$pkg"
      return 0
    fi
  done

  [ $fatal -eq 0 ] && lum::err "could not find package for '$1'"
  return 1
}

lum::help::cli::+pkg-conf() {
  local pkgdir="$1" lib ns
  local -i fatal="$2"

  local PACKAGE VERSION
  local -a CALLED
  local -A BIN LIB DEPS

  . "$pkgdir/PACKAGE.conf"

  for lib in "${!LIB[@]}"; do
    libdir="$pkgdir/$lib"
    ns="${LIB[$lib]}"
    lum::use::libdir "$libdir" "$ns"
  done
}

lum::fn lum::help::cli.opts 2 -t 0 7
#$
#
# Options for ``lum::help::cli``
#
# ``-P <<package>>``      Add a specific package.
# ``-L <<libname>>``      Add a library from a current package.
# ``-l [[prefix]]``       Show a list of commands and exit.
#                     If ((prefix)) is set, filter the list with it.
#                     If not specified, default is: ``lum::``
#
#: lum::help::cli.opts
