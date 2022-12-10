#$< lum::user
# User information functions

lum::var LUM_USER_CONF_DIR =? ".lum"

lum::use lum::use::from

lum::fn lum::user::appDir 0
#$ <<dirname>>
#
# Set the app-specific user config sub-directory.
#
# This is a sub-directory in the user's home directory that
# can contain configuration files specific to the app.
# 
# This is currently set to $var(LUM_USER_CONF_DIR);
#
lum::user::appDir() {
  [ $# -eq 0 ] && lum::help::usage
  LUM_USER_CONF_DIR="$1"
}

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
#$ [[scriptDir=0]]
#
# Get the logged in user's config directory.
#
# ((scriptDir))    If ``1``, use script-specific config dir.
#              
lum::user::conf() {
  local scriptDir="${1:-0}" homeDir="$(lum::user::home)" 
  local confDir="$homeDir/$LUM_USER_CONF_DIR"
  [ "$scriptDir" = "1" ] && confDir+="/$SCRIPTNAME"
  echo "$confDir"
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
