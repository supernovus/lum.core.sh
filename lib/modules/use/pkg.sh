#$< lum::use::pkg
# Support for loading lum.sh PACKAGE.conf files.

LUM_INST_PKG="$(dirname "$LUM_CORE_PKG_DIR")"

declare -gi LUM_INST_DEV=0 LUM_USE_PKG_FATAL=1
declare -ga LUM_PKG_ROOTS=("$LUM_INST_PKG")
lum::var LUM_PKG_SCOPE =? '.'

lum::use --conf --opt site-packages

# Internal function to detect the core installation type
lum::use::pkg--detect-core() {
  local coreName="$(basename "$LUM_CORE_PKG_DIR")"
  case "$coreName" in 
    lum-core)
      LUM_INST_DEV=0
    ;;
    core)
      LUM_INST_DEV=1
    ;;
    *)
      lum::err "invalid lum-core installation" 250
    ;;
  esac
}

if [ -n "$LUM_SITE_PKG" ]; then
  ## If called from lum-pkg, we've already loaded the installation.conf
  LUM_PKG_ROOTS+=("$LUM_SITE_PKG")
else
  ## Figure out the layout of the package installation.
  lum::use::pkg--detect-core
fi

lum::use::pkg() {
  local cacheKey="@pkg:${1/::/-}"
  [ "${LUM_USE_NAMES[$cacheKey]}" = "1" ] && return
  local pkgdir="$(lum::pkg::find "$1")"
  [ $? -eq 0 ] && lum::use::pkg::conf "$pkgdir"
  LUM_USE_NAMES[$cacheKey]=1
}

lum::pkg::find() {
  local pkg="${1/::/-}"
  local -n fatal="LUM_USE_PKG_FATAL"

  [ $LUM_INST_DEV -eq 1 ] && pkg="${pkg/lum-/}"

  local pdir
  for pdir in "${LUM_PKG_ROOTS[@]}"; do
    if [ -d "$pdir/$pkg" -a -f "$pdir/$pkg/PACKAGE.conf" ]; then
      echo "$pdir/$pkg"
      return 0
    fi
  done

  [ $fatal -eq 1 ] && lum::err "could not find package for '$1'"
  return 1
}

lum::use::pkg::conf() {
  local pkgdir="$1" lib ns spec

  local PACKAGE VERSION
  local -a AUTO
  local -A BIN LIB ETC DEPS

  . "$pkgdir/PACKAGE.conf"

  for lib in "${!LIB[@]}"; do
    libdir="$pkgdir/$lib"
    ns="${LIB[$lib]}"
    lum::use::libdir "$libdir" "$ns"
  done

  for spec in "${AUTO[@]}"; do
    lum::use::pkg::conf-auto $spec
  done
}

lum::use::pkg::conf-auto() {
  local when="$1" type="$2" target="$3"
  local from="$LUM_PKG_SCOPE"
  if [[ $when == "*" || $from =~ $when ]]; then
    case "$type" in
      src)
        . "$pkgdir/$target"
      ;;
      use)
        lum::use "$target"
      ;;
      *)
        lum::warn "unknown AUTO action '$type'"
      ;;
    esac
  fi
}
