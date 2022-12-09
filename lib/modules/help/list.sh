#$< lum::help::list
# Listing capabilities for the help system.

lum::use lum::var::more

lum::var -P LUM_HELP_ \
  -A= LIST_OPTS \
    pad    = -1 \
    max    = 0 \
    sort   = 0 \
    follow = 1 \
    sep    = " → " \
    prefix = " " \
    suffix = " " \
    nl     = "  " \
    - \
  -A= TOPICS_OPTS \
    max    = -1 \
    sort   = 1 \
    follow = 0 \
    - 

lum::fn lum::help::list
#$ <<list>> [[display]] [[fullDisp=0]]
#
# Print a list of commands from a list (array variable).
#
# ((list))      The name of the list variable.
# ((display))   The name of a variable with display settings.
#           If not specified (or ``-``) we use global defaults.
#           See ``lum::help::list.display`` for details.
# ((fullDisp))  If ``1`` then ((display)) must have ALL settings defined.
#
lum::help::list() {
  [ $# -lt 1 ] && lum::help::usage

  local -n sourceList="$1"
  local -i fullDisp="${3:-0}"

  if [ $fullDisp -eq 1 ]; then
    local -n listOpts="$2"
  else
    local -A listOpts
    lum::var::merge listOpts LUM_HELP_LIST_OPTS "$2"
  fi

  local sep="${listOpts[sep]}"
  local pf="${listOpts[prefix]}"
  local sf="${listOpts[suffix]}"
  local nl="${listOpts[nl]}"
  local -i max="${listOpts[max]}"
  local -i follow="${listOpts[follow]}"
  local -i pad="${listOpts[pad]}"
  local -i sort="${listOpts[sort]}"

  local ic="${LUM_THEME[help.item]}"
  local sc="${LUM_THEME[help.syntax]}"
  local pc="${LUM_THEME[help.param]}"
  local ec="${LUM_THEME[end]}"

  local C K U W
  local -i L

  if [ $pad -eq -1 ]; then
    local -a tempList=()
    lum::help::+list sourceList tempList pad
    sourceList=("${tempList[@]}")
    (( pad += ${#pf} + ${#sf} ))
  fi

  if [ $sort -eq 1 ]; then
    local -a tempList=()
    lum::var::sort sourceList tempList
    sourceList=("${tempList[@]}")
  fi

  [ $max -eq -1 ] && max="$(lum::help::width)"

  for K in "${sourceList[@]}"; do
    C="$(lum::str::pad $pad "$pf$K$sf")"
    if [ $follow -eq 0 -a -n "${LUM_ALIAS_FN[$K]}" ]; then
      U="$pc${LUM_ALIAS_FN[$K]}$ec"
      W="$pc$ec"
    else
      U="$ec$(lum::help $K 2)"
      W="$ec"
    fi
    L=$(( ${#C} + ${#U} + ${#sep} - ${#W} ))
    if [ $max -gt 0 -a $L -gt $max ]; then
      #lum::warn "+wrapping: max=$max; lc=${L}"
      echo "$ic$C"
      echo "${hc[s]}$nl$sep$U"
    else
      echo "$ic$C${hc[s]}$sep$U"
    fi
  done
}

lum::fn lum::help::list.display 2
#$ 
#
# Display variables for lum::help::list
#
# Must be declared as ``-A`` associative array type variables.
# May contain any of the following settings:
#
# Name/Key        Default      Description
#
# ``pad``           `{-1}`           Pad each item name to be this long.
#                              - If ``-1``, determine automatically.
#                              - If ``0``, no padding done.
# ``max``           `{0}`            Max width of a line before we wrap.
#                              - If ``-1``, determine automatically.
#                              - If ``0``, no line wrapping done.
# ``sep``           `{" → "}`        Separator between name and description.
# ``prefix``        `{" "}`          Display at the start of the item name.
# ``suffix``        `{" "}`          Display at the end of the item name.
# ``nl``            `{"  "}`         Prefix for wrapped lines (see ``max``).
# ``sort``          `{0}`            Sort the list before displaying?
# ``follow``        `{1}`            Follow aliases for description?
#                              - If ``0``, show the target name instead.
#
# Any setting not explicitly set, will use the default.
#
#: lum::help::list.display

lum::fn lum::help::topics
#$ <<types>> [[find]] [[display]]
#
# Show a list of functions and/or help topics.
#
# ((types))      What types of topics to list (as bitwise flags).
#            At least one flag **MUST** be specified.
#
#            ``1`` = Show functions/topics registered with ``lum::fn``.
#            ``2`` = Show aliases registered with ``lum::fn(::alias)``.
#
# ((find))       Show only items containing this value.
# ((display))    The name of a variable with display settings.
#            See ``lum::help::topics.display`` for details.
#
lum::help::topics() {
  local -i flags="${1:-0}"

  if [ $flags -eq 0 ]; then
    lum::err "no type flags specified"
  else
    local -A topicsDisplayOpts
    lum::var::merge topicsDisplayOpts \
      LUM_HELP_LIST_OPTS \
      LUM_HELP_TOPICS_OPTS \
      "$3"

    local find="$2"
    local -ir FN=1 FA=2
    local -i pad="${topicsDisplayOpts[pad]}"
    local pf="${topicsDisplayOpts[prefix]}"
    local sf="${topicsDisplayOpts[suffix]}"
    local -a topicList
    local fn ref padVar

    [ $pad -eq -1 ] && padVar='pad' || padVar='-'

    if lum::flag::is $flags $FN; then
      lum::help::+map LUM_FN_FILES topicList $padVar "$find"
    fi

    if lum::flag::is $flags $FA; then
      lum::help::+map LUM_ALIAS_FN topicList $padVar "$find"
    fi

    if [ "${#topicList[@]}" -eq 0 ]; then
      lum::warn "no matching topics"
      return 1
    fi

    if [ $pad -gt 0 ]; then
      (( pad += ${#pf} + ${#sf} ))
      topicsDisplayOpts[pad]=$pad
    fi

    lum::help::list topicList topicsDisplayOpts 1
  fi
  
  return 0
}

lum::fn lum::help::topics.display 2
#$ 
#
# Display variables for lum::help::topics
#
# Uses the same settings as ``lum::help::list``, but a few of the 
# settings have different default values:
#
# Name/Key        Default      Reasoning for difference
#
# ``max``           `{-1}`           Auto-wrapping is desired here.
# ``sort``          `{1}`            Allows for a known topic order.
# ``follow``        `{0}`            If listing aliases, show the target.
#
# See ``lum::help::list.display`` for the full list of settings.
#
#: lum::help::topics.display

lum::help::+map() {
  local -n helpMapVar="$1"
  local -a helpMapList=("${!helpMapVar[@]}")
  lum::help::+list helpMapList "$2" "$3" "$4"
}

lum::help::+list() {
  local fn
  local -n helpInputList="$1"
  local -n helpOutputList="$2"
  local -i currPad=-1
  if [ -n "$3" -a "$3" != "-" ]; then
    currPad=0
    local -n maxiPad="$3"
  fi
  local find="$4"

  for fn in "${helpInputList[@]}"; do
    if [ -n "$find" ]; then
      [[ $fn =~ $find ]] || continue
    fi
    helpOutputList+=("$fn")
    if [ $currPad -gt -1 ]; then
      currPad="${#fn}"
      [ $currPad -gt $maxiPad ] && maxiPad=$currPad
    fi
  done
}
