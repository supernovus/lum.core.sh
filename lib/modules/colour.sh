#$< lum::colour
# ANSI Colours for your terminal

[ -z "$LUM_COLOUR_TEST" ] && LUM_COLOUR_TEST=1

lum::fn lum::colour::isSupported
#$ --
#
# Test if the current terminal supports colours.
#
lum::colour::isSupported() {
  case "$TERM" in
    xterm*|linux|ansi|screen)
      return 0
    ;;
    *)
      return 1
    ;;
  esac
}

if [ "$LUM_COLOUR_TEST" = "1" -a ! lum::colour::isSupported ]; then
  ## Set a fake colour() function placeholder.
  lum::colour() { return; }
  return
fi

lum::fn lum::colour
#$ [options...]
#
# Set colour definitions.
#
# Can take multiple parameters, each of which can be one of the 
# supported colours, or one of a few different command tokens:
#
#  'fg'         Apply the following to foreground colours.
#  'bg'         Apply the following to background colours.
#
#  'bold'       Make the following *bold* colours.
#               Aliases: 'light', 'bright'.
#  'dark'       Make the following *dark* colours.
#               Aliases: 'unbold', 'thin'.
#  
#  'end'        Reset back to regular text formatting.
#               Aliases: 'reset', 'normal', 'plain'.
#
# Supported colours:
#
#  'black', 'white', 'blue', 'green', 'cyan', 'red', 'purple', 'yellow'.
#
lum::colour() {
  local target=fg output
  local -A colours 
  colours[fg]=-1
  colours[bg]=-1
  colours[bold]=0

  for arg in $@
  do 
    case "$arg" in
      fg)
        target=fg
      ;;
      bg)
        target=bg
      ;;
      light|bold|bright)
        colours[bold]=1
      ;;
      dark|unbold|thin)
        colors[bold]=0
      ;;
      black)
        colours[$target]=0
      ;;
      white)
        colours[$target]=7
      ;;
      blue)
        colours[$target]=4
      ;;
      green)
        colours[$target]=2
      ;;
      cyan)
        colours[$target]=6
      ;;
      red)
        colours[$target]=1
      ;;
      purple)
        colours[$target]=5
      ;;
      yellow)
        colours[$target]=3
      ;;
      end|normal|reset|plain)
        echo -en "\033[00m"
        return
      ;;
    esac
  shift 
  done
  output="${colours[bold]}";
  [ "${colours[fg]}" -ne -1 ] && output="$output;3${colours[fg]}"
  [ "${colours[bg]}" -ne -1 ] && output="$output;4${colours[bg]}"
  echo -en "\033[${output}m"
}
