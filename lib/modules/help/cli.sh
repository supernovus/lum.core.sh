#@lib: lum::help::cli
#@desc: An advanced CLI help script for Lum.sh
#@desc: Not meant for use by anything other than lum-core/bin/help.sh

[ -n "$LUM_CORE_PKG_DIR" -a -d "$LUM_CORE_PKG_DIR" ] || lum::err "Not supported"

lum::use lum::themes::default lum::getopts

LUM_INST_PKG="$(dirname "$LUM_CORE_PKG_DIR")"
LUM_CORE_NAME="$(basename "$LUM_CORE_PKG_DIR")"

declare -gi LUM_INST_DEV=0
declare -ga LUM_PKG_ROOTS=("$LUM_INST_PKG")
declare -gr LUM_PKG_INST_CONF="$LUM_INST_PKG/lum-pkg/etc/installation.conf"

case "$LUM_CORE_NAME" in 
  lum-core)
    if [ -f "$LUM_PKG_INST_CONF" ]; then
      . "$LUM_PKG_INST_CONF"
      [ -n "$LUM_SITE_PKG" -a "$LUM_SITE_PKG" != "$LUM_INST_PKG" ] \
        && LUM_PKG_ROOTS+=("$LUM_SITE_PKG")
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

lum::fn lum::help::cli 0 -a "$SCRIPTNAME" 1 0
#$ [[options...]] <<topic>>
#
# Look up a help topic
#
# ((options))      See ``lum-help-opts`` for details.
# ((topic))        The name of a function or standalone help topic.
#
lum::help::cli() {
  lum::getopts lh

  lh::def P pkg '+' L lib '+' l list '#' u usage '#'
  lh::parse 1 "$@"

  local -n OPTS="$(lh::opts)"
  local -n ARGS="$(lh::args)"
  local -n PKGS="$(lh::+pkg)"
  local -n LIBS="$(lh::+lib)"

  local -i showList="${OPTS[list]:-0}"
  local pkg lib

  for pkg in "${PKGS[@]}"; do
    lum::help::cli::+pkg "$pkg"
  done

  for lib in "${LIBS[@]}"; do
    lum::use "$lib"
  done

  if [ $showList -gt 0 ]; then
    lum::help::topics $showList "$ARGS"
    exit
  fi

  local -i usage="${OPTS[usage]:-0}"

  lum::help "$ARGS" $usage
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

lum::fn lum::help::cli.opts 6 -t 0 7 -a lum-help-opts 1 0
#$ Options for lum-help CLI
#
# ``-P <<package>>``      Add a specific Lum.sh package.
# ``-L <<libname>>``      Add a library from a package.
#
# ``-u``                Show only the usage line.
#                     Use doubled ((``-uu``)) to show only the summary line.
#
# ``-l``                Show a list of help topics and exit.
#                     Use doubled (``-ll``) to show ONLY aliases.
#                     Use tripled (``-lll``) to show topics AND aliases.
#
#                     If a ((topic)) is specified with ``-l``, show only 
#                     topics matching that string as a simple RegEx.
#
#: lum::help::cli.opts
