#@lib: lum::readline
#@desc: For some reason Bash disables completion when using `read -e`;
#@desc: That ridiculous decision has made this library necessary.

lum::fn lum::readline 4
#$ - Enable our readline wrapper
#
# Binds TAB to a function that finds a completion handler
# (set with ``complete``), and passes it to ``compgen``;
# then parses the results from that and either displays available 
# completion items, or if only one remains, fills it in.
#
lum::readline::enable() {
  bind -x '"\t":"lum::readline::handle"'
}

lum::readline::handle() {
  lum::err TODO
}

lum::readline::disable() {
  bind -r '"\t"'
}
