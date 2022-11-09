## User related functions

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100
[ -z "$LUM_USER_CONF_DIR" ] && LUM_USER_CONF_DIR=".lum"

lum::use lum::use::from

lum::lib lum::user $LUM_CORE

lum::fn lum::user::home 
#$ `{--}`
#
# Get the logged in user's home directory.
#
# This is not the same as ``$HOME`` as that variable can be affected
# by the use of ``sudo``, whereas this uses the actual user logged in.
#
lum::user::home() {
  which getent >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo $(getent passwd $(logname) | cut -d: -f6)
  else
    echo $(grep "$(logname):x:" /etc/passwd | cut -d: -f6)
  fi
}

lum::fn lum::user::conf 
#$ `{--}`
#
# Get the logged in user's config directory.
#
lum::user::conf() {
  local HOMEDIR="$(lum::user::home)"
  echo "$HOMEDIR/$LUM_USER_CONF_DIR"
}

lum::fn lum::user::libs 
#$ `{--}`
#
# Use modular libraries from the user config directory.
#
lum::user::libs() {
  local USERCONF="$(lum::user::conf)"
  lum::use::from "$USERCONF"
  lum::use::from "$USERCONF/$SCRIPTNAME"
}
