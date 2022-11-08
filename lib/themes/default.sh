## Default theme

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::use lum::colour

LUM_THEME[end]=$(lum::colour end)

LUM_THEME[error]=$(lum::colour bold red)

LUM_THEME[diag.func]=$(lum::colour yellow)
LUM_THEME[diag.file]=$(lum::colour blue)

LUM_THEME[help.syntax]=$(lum::colour light black)
LUM_THEME[help.arg]=$(lum::colour bold blue)
LUM_THEME[help.opt]=$(lum::colour dark cyan)
LUM_THEME[help.def]=$(lum::colour dark yellow)
LUM_THEME[help.param]=$(lum::colour bold cyan)
LUM_THEME[help.value]=$(lum::colour bold yellow)
LUM_THEME[help.list.item]=$(lum::colour bold green)

