#@lib: lum::readline
#@desc: For some reason Bash disables completion when using `read -e`;
#@desc: That ridiculous decision has made this library necessary.

lum::fn lum::readline 4
#$ - Enable the readline wrapper
lum::readline::enable() {
  bind -x '"\t":"lum::readline::handle"'
}

lum::readline::handle() {
  lum::err TODO
}

lum::fn lum::readline::disable 4
#$ - Disable the readline wrapper
lum::readline::disable() {
  bind -r '"\t"'
}
