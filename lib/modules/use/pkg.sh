#$< lum::use::pkg
# Support for using installed lum.sh packages.

lum::use lum::pkg
lum::var -i LUM_USE_PKG_FATAL =? 1 

lum::use::pkg() {
  local cacheKey="@pkg:${1//::/-}"
  [ "${LUM_USE_NAMES[$cacheKey]}" = "1" ] && return 0

  lum::pkg::conf "$1" 'lum::use::pkg--conf'
  local -i retVal=$?
  if [ $LUM_USE_PKG_FATAL -eq 1 -a $retVal -ne 0 ]; then
    lum::err "could not find installed package for '$1'"
  fi
  LUM_USE_NAMES[$cacheKey]=1
  return $retVal
}

lum::use::pkg--conf() {
  local dir ns spec

  for dir in "${!LIB[@]}"; do
    ns="${LIB[$dir]}"
    lum::use::libdir "$pkgDir/$dir" "$ns"
  done

  for dir in "${CONF[@]}"; do
    lum::use::confdir "$pkgDir/$dir"
  done

  for spec in "${AUTO[@]}"; do
    lum::use::pkg--conf-auto $spec
  done

  return 0
}

lum::use::pkg--conf-auto() {
  local when="$1" type="$2" target="$3"
  if [[ $when == "*" || $scope =~ $when ]]; then
    case "$type" in
      src)
        . "$pkgDir/$target"
      ;;
      use)
        lum::use "$target"
      ;;
      use-conf)
        lum::use --conf --opt "$target"
      ;;
      need-conf)
        lum::use --conf "$target"
      ;;
      libdir)
        lum::use::libdir "$pkgDir/$target"
      ;;
      confdir)
        lum::use::confdir "$pkgDir/$target"
      ;;
      *)
        lum::warn "unknown AUTO action '$type'"
      ;;
    esac
  fi
}

#$ lum::use::pkg,auto - Auto-run statements
#
# TODO: document this
#
#: lum::use::pkg,auto
