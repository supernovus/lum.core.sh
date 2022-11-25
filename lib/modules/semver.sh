#@lib: lum::semver
#@desc: A bare-bones Semantic Versioning 2.0.0 library
#@desc: It is based on several functions from semver-tool,
#@desc: modified for parsing and comparison purposes only.
#@see: https://github.com/fsaintjacques/semver-tool
#@see: https://semver.org

LUM_SEMVER_NAT='0|[1-9][0-9]*'
LUM_SEMVER_ALPHANUM='[0-9]*[A-Za-z-][0-9A-Za-z-]*'
LUM_SEMVER_IDENT="$LUM_SEMVER_NAT|$LUM_SEMVER_ALPHANUM"
LUM_SEMVER_FIELD='[0-9A-Za-z-]+'

LUM_SEMVER_REGEX="\
^[vV]?\
($LUM_SEMVER_NAT)\\.($LUM_SEMVER_NAT)\\.($LUM_SEMVER_NAT)\
(\\-(${LUM_SEMVER_IDENT})(\\.(${LUM_SEMVER_IDENT}))*)?\
(\\+${LUM_SEMVER_FIELD}(\\.${LUM_SEMVER_FIELD})*)?$"

lum::fn lum::semver::parse
#$ <<version>> <<varname>> [[raw=0]]
#
# Parse a version string into an array variable
#
# ((version))      A SemVer 2.0.0 version string.
#
# ((varname))      Name of the variable to export to.
# 
# ((raw))          The format of the returned array.
#              ``0`` = Default: `{(major minor patch prere build)}`
#              ``1`` = Raw array of RegExp matches.
#
# Only the first three fields are guaranteed to have a proper numeric value.
# The other fields may be empty if there was no pre-release or build info.
#
# If the version is not a valid SemVer string, the error code will be ``1``.
#
lum::semver::parse() {
  [ $# -lt 2 ] && lum::help::usage
  local version="$1"
  local -n var="$2"
  local -i raw="${3:-0}"
  if [[ $version =~ $LUM_SEMVER_REGEX ]]; then
    if [ $raw -eq 0 ]; then
      local major=${BASH_REMATCH[1]}
      local minor=${BASH_REMATCH[2]}
      local patch=${BASH_REMATCH[3]}
      local prere=${BASH_REMATCH[4]}
      local build=${BASH_REMATCH[8]}
      var=("$major" "$minor" "$patch" "$prere" "$build")
      #eval "$2=(\"$major\" \"$minor\" \"$patch\" \"$prere\" \"$build\")"
    else
      var=("${BASH_REMATCH[@]}")
    fi
    return 0
  else
    return 1
  fi
}

lum::semver::isNat() {
  [[ "$1" =~ ^($LUM_SEMVER_NAT)$ ]]
}

lum::semver::isNull() {
  [ -z "$1" ]
}

lum::semver::orderNat() {
  [ "$1" -lt "$2" ] && { echo -1 ; return ; }
  [ "$1" -gt "$2" ] && { echo 1 ; return ; }
  echo 0
}

lum::semver::orderStr() {
  [[ $1 < $2 ]] && { echo -1 ; return ; }
  [[ $1 > $2 ]] && { echo 1 ; return ; }
  echo 0
}

# given two (named) arrays containing LUM_SEMVER_NAT and/or LUM_SEMVER_ALPHANUM fields, compare them
# one by one according to semver 2.0.0 spec. Return -1, 0, 1 if left array ($1)
# is less-than, equal, or greater-than the right array ($2).  The longer array
# is considered greater-than the shorter if the shorter is a prefix of the longer.
#
lum::semver::compareFields() {
  local l="$1[@]"
  local r="$2[@]"
  local leftfield=( "${!l}" )
  local rightfield=( "${!r}" )
  local left
  local right

  local i=$(( -1 ))
  local order=$(( 0 ))

  while true
  do
    [ $order -ne 0 ] && { echo $order ; return ; }

    : $(( i++ ))
    left="${leftfield[$i]}"
    right="${rightfield[$i]}"

    lum::semver::isNull "$left" \
      && lum::semver::isNull "$right" \
      && { echo 0  ; return ; }
    lum::semver::isNull "$left" \
      && { echo -1 ; return ; }
    lum::semver::isNull "$right" \
      && { echo 1  ; return ; }

    lum::semver::isNat "$left" \
      && lum::semver::isNat "$right" \
      && { order=$(lum::semver::orderNat "$left" "$right") ; continue ; }
    lum::semver::isNat "$left" \
      && { echo -1 ; return ; }
    lum::semver::isNat "$right" \
      && { echo 1  ; return ; }

    { order=$(lum::semver::orderStr "$left" "$right") ; continue ; }
  done
}

# shellcheck disable=SC2206     # checked by "validate"; ok to expand prerel id's into array
lum::fn lum::semver::compare
#$ <<ver1>> <<ver2>>
#
# Compare two SemVer 2.0.0 format version strings
#
# ((ver1))      The first version string
#
# ((ver2))      The second version string
#
# Will echo the result to `{STDOUT}` as one of these values:
#
#  ``0``  = The versions were the same.
#  ``1``  = ((ver1)) was higher.
# ``-1``  = ((ver2)) was higher.
#
lum::semver::compare() {
  [ $# -lt 2 ] && lum::help::usage
  
  local order
  lum::semver::parse "$1" V1
  lum::semver::parse "$2" V2

  # compare major, minor, patch

  local left=( "${V1[0]}" "${V1[1]}" "${V1[2]}" )
  local right=( "${V2[0]}" "${V2[1]}" "${V2[2]}" )

  order=$(lum::semver::compareFields left right)
  [ "$order" -ne 0 ] && { echo "$order" ; return ; }

  # compare pre-release ids when M.m.p are equal

  local prerel1="${V1[3]:1}"
  local prerel2="${V2[3]:1}"
  local left=( ${prerel1//./ } )
  local right=( ${prerel2//./ } )

  # if left and right have no pre-release part, then left equals right
  # if only one of left/right has pre-release part, that one is less than simple M.m.p

  [ -z "$prerel1" ] && [ -z "$prerel2" ] && { echo 0  ; return ; }
  [ -z "$prerel1" ]                      && { echo 1  ; return ; }
                       [ -z "$prerel2" ] && { echo -1 ; return ; }

  # otherwise, compare the pre-release id's

  lum::semver::compareFields left right
}
