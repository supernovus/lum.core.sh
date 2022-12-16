#< lum::help::cli
# An advanced CLI help script for Lum.sh
# Not meant for use by anything other than lum-core/bin/help.sh

lum::use lum::help::list lum::themes::default lum::getopts lum::use::pkg 

lum::fn lum::help::cli 0 -a "$SCRIPTNAME" 1 0 -a help 0 0 -h opts more
#$ [[options...]] <<topic>>
#
# Look up a help topic
#
# ((topic))        The name of a function or standalone help topic.
#              Sub-topics are marked by a comma: ``topic,subtopic``.
#
# See $see(help,opts); for a list of ((options)).
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
    lum::use::pkg "$pkg"
  done

  for lib in "${LIBS[@]}"; do
    lum::use "$lib"
  done

  if [ $showList -gt 0 ]; then
    lum::help::topics $showList "$ARGS"
    return
  fi

  local -i usage="${OPTS[usage]:-0}"

  lum::help "$ARGS" $usage
}

#$ lum::help::cli,opts - CLI options
#
# ``-P <<package>>``      Add a specific Lum.sh package.
# ``-L <<libname>>``      Add a library from a package.
#
# ``-u``                Show only the usage line.
#                     Use doubled (``-uu``) to show only the summary line.
#
# ``-l``                Show a list of help topics and exit.
#                     Use doubled (``-ll``) to show ONLY aliases.
#                     Use tripled (``-lll``) to show topics AND aliases.
#
#                     If a ((topic)) is specified with ``-l``, show only 
#                     topics matching that string as a simple RegEx.
#
#: lum::help::cli,opts
