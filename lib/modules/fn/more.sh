#$< lum::fn::more
# Additional function related methods

lum::fn lum::fn::list
#$ [[prefix]] 
#
# Show a list of functions.
#
# ((prefix))    Show only functions starting with this.
#
lum::fn::list() {
  compgen -A function "$1"
}
