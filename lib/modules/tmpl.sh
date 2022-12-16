#@lib: lum::tmpl
#@desc: A cheap template engine

declare -gA LUM_TMPL_OPTS=(\
  [file]='-' \
  [bls]='\{\{' \
  [ble]='\}\}' \
)

lum::fn lum::tmpl
#$ [[optvar]]
#
# Parse a template.
#
# If the template block content starts with a ``$`` character, it's
# a variable to echo. Anything else is considered a function to run.
# The ``STDOUT`` from the variable or function will be used as the 
# replacement for the block.
#
# ((optvar))      The name of a ``-A`` var of options.
#             See $see(,opts); for a list of valid options.
#
lum::tmpl() {
  local -A __
  lum::var::merge __ LUM_TMPL_OPTS $@

  __[blockre]="(.*?)${__[bls]}\s*(.*?)${__[ble]}(.*)"

  [ -z "${__[text]}" ] && __[text]="$(cat ${__[file]})" 

  if [ -n "${__[vars]}" -a "$(lum::var::type "${__[vars]}")" = "-A" ]; then
    if [ -n "${__[varsref]}" ]; then
      local _vr="$(lum::var::id ${__[varsref]})"
      [ "$_vr" = '__' ] && lum::err "'__' is a reserved name"
      local -n $_vr="${__[vars]}"
      unset _vr
    else
      local -n _vs="${__[vars]}"
      local _k _v
      for _k in "${!_vs[@]}"; do
        _k="$(lum::var::id $_k)"
        _v="${_vs[$_k]}"
        local $_k="$_v"
      done
      unset _k _v
    fi
  fi

  if [ -n "${__[exts]}" ]; then
    local _te
    for _te in ${__[exts]}; do
      lum::tmpl::+$_te
    done
    unset _te
  fi

  while [[ ${__[text]} =~ ${__[blockre]} ]]; do
		__[line]="${BASH_REMATCH[2]}"
		[ "${__[line]:0:1}" = '$' ] && __[line]="echo ${__[line]}"
		__[line]="$(eval ${__[line]})"
    __[text]="${BASH_REMATCH[1]}${__[line]}${BASH_REMATCH[3]}"
  done

  echo "${__[text]}"
}

#$ lum::tmpl,opts - Common settings
#
# $b(Option);       $b(Default);          $b(Description);
#
# ``text``       ''               The template text to parse.
#                               If left blank, ``file`` is used instead.
# ``file``       ``-``              Filename to parse, ``-`` is ``STDIN``.
# ``bls``        ``\{\{``           RegExp for the start of a block.
# ``ble``        ``\}\}``           RegExp for the end of a block.
# ``vars``       ``''``             Name of a ``-A`` map of template vars.
#                               If left blank, no template vars are used.
# ``varsref``    ''               Name to export ``vars`` reference to.
#                               If left blank, export a separate variable 
#                               for every key in the ``vars`` array.
# ``exts``        ''              Space-separated list of extensions.
#                                ``if`` → Adds ``IF ...`` ``ELSE`` ``ENDIF``
#: lum::tmpl,opts

#$ lum::tmpl,if - Simple IF statements
#
# Currently only supports binary-branch, non-nested conditional statements.
# Examples using the default ((bls)) and ((ble)) strings for simplicity.
#
# $v({{IF ((condition))}});
# $s(Template text if condition is true);
# $v({{ELSE}});
# $s(Template text if condition is false);
# $v({{ENDIF}});
# 
#: lum::tmpl,if

lum::tmpl::+if() {
  __[ifre]="(.*?)${__[bls]}\s*IF\s+(.*?)${__[ble]}(.*?)${__[bls]}"
  __[ifre]+="(ELSE${__[ble]}(.*?)${__[bls]})?ENDIF${__[ble]}(.*)"

  while [[ ${__[text]} =~ ${__[ifre]} ]]; do
    eval "${BASH_REMATCH[2]}" >/dev/null
    if [ $? -eq 0 ]; then
      __[line]="${BASH_REMATCH[3]}"
    else
      __[line]="${BASH_REMATCH[5]}"
    fi
    __[text]="${BASH_REMATCH[1]}${__[line]}${BASH_REMATCH[6]}"
  done
}

lum::fn lum::tmpl::forHelp
#$ [[name=tmpl]] [[moreopts=0]]
#
# Register a help definition using lum::tmpl
#
lum::tmpl::forHelp() {
  local name="${1:-tmpl}" moreopts="${2:-0}"
  lum::help::def "$name" P- lum::tmpl "$moreopts"
}
