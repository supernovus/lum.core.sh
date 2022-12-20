#$< lum::pkg
# Simplistic bash packages installed from git.

[ -z "$LUM_INST_PKG" ] && LUM_INST_PKG="$(dirname "$LUM_CORE_PKG_DIR")"

lum::var -i LUM_INST_DEV =? -1
lum::var -P LUM_PKG_ \
  SCOPE =? '.' \
  -a= ROOTS \
    "$LUM_INST_PKG" \
    - \
  -A PATHS

# Initialize the package variables.
lum::pkg--init() {
  lum::use --conf --opt site-packages

  [ -n "$LUM_SITE_PKG" ] && LUM_PKG_ROOTS+=("$LUM_SITE_PKG")

  if [ $LUM_INST_DEV -eq -1 ]; then 
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
  fi
}

lum::pkg--init 

lum::fn lum::pkg::find
#$ <<pkgId>>
#
# Find an installed package directory
# Outputs the directory path to ``STDOUT``.
#
# ((pkgId))     The package name or identifier (e.g. ``lum-core``).
#
# Return value ``1`` indicates no valid package directory found.
#
lum::pkg::find() {
  local pkgId="${1//::/-}"
  local -r pkgMD='PACKAGE.conf'

  local -n pkgPaths="LUM_PKG_PATHS"
  if [ -n "${pkgPaths[$pkgId]}" ]; then
    echo "${pkgPaths[$pkgid]}"
    return 0
  fi

  local pkgName="$pkgId"
  [ $LUM_INST_DEV -eq 1 ] && pkgName="${pkgName/lum-/}"

  local pkgRoot
  for pkgRoot in "${LUM_PKG_ROOTS[@]}"; do
    if [ -d "$pkgRoot/$pkgName" -a -f "$pkgRoot/$pkgName/$pkgMD" ]; then
      pkgPaths[$pkgId]="$pkgRoot/$pkgName"
      echo "$pkgRoot/$pkgName"
      return 0
    fi
  done

  return 1
}

lum::fn lum::pkg::conf
#$ <<pkgId>> <<command>> [[args...]]
#
# Load a package config and run a command with it.
#
# ((pkgId))     The package name or identifier.
# ((command))   The function to run in the nested function scope.
# ((args))      Any arguments to pass to the ((command)) function.
#
# 
lum::pkg::conf() {
  [ $# -lt 2 ] && lum::help::usage
  local pkgId="${1//::/-}" command="$2" pkgDir scope="$LUM_PKG_SCOPE"
  local -r pkgMD='PACKAGE.conf'

  pkgDir="$(lum::pkg::find "$1")"
  local -i retVal=$?
  [ $retVal -ne 0 ] && return $retVal

  local PACKAGE VERSION
  local -a AUTO CONF
  local -A BIN LIB DEPS

  shift 2

  . "$pkgDir/$pkgMD"

  "$command" "$@"
}

#$ lum::pkg::conf,vars - Configuration Variables
#
# $h(name          type           description);
#
# ((pkgId))        $v(--);        The requested package id
# ((pkgDir))       $v(--);        The installation directory
# ((command))      $v(--);        The command being ran
# ((scope))        $v(--);        The current scope (default ``.``)
#
# $a(PACKAGE);     $v(--);        Package id from PACKAGE.conf
# $a(VERSION);     $v(--);        Version number (e.g. ``1.0.0``)
# $o(BIN);         $v(-A);        Script name => Package file
# $o(LIB);         $v(-A);        Package lib sub-dir => Namespace prefix
# $o(DEPS);        $v(-A);        Dep package id => Minimum version
# $o(CONF);        $v(-a);        Package config sub-dirs
# $o(AUTO);        $v(-a);        Auto-run statements
#
#: lum::pkg::conf,vars
