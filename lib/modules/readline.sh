#@lib: lum::readline
#@desc: For some reason Bash disables completion when using `read -e`;
#@desc: That ridiculous decision has made this library necessary.

lum::var -P LUM_READLINE_ COMP_HANDLER

lum::fn lum::readline
#$ [[fn]]
#
# Enable our readline wrapper
#
# ((fn))      The ``compgen`` handler function.
#         If not specified, we check ``complete -D`` for one.
#
lum::readline() {
  local compHandler="$1"
  if [ -z "$compHandler" ]; then
    local compDefault="$(complete -p -D 2>/dev/null)"
    [ -z "$compDefault" ] && lum::err "No completion handler found"
  fi
  lum::err TODO
}

lum::readline::handle() {
  lum::err TODO
}

lum::readline::undo() {
  lum::err TODO
}
