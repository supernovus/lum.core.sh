#$< lum::test::completion
# Completion handler for the testing shell
# Not meant for use by anything other than lum-core/bin/test.sh

lum::use lum::readline

lum::test::completion::enable() {
  #complete -F lum::test::completion -D
  lum::err TODO - the format of this will depend on lum::readline
}

lum::test::completion() {
  lum::warn "shell::comp($1): $2"
  case "$1" in
    "lum::help"|"//h")
      local -A knownTopics
      lum::var::merge knownHelpTopics LUM_FN_FILES LUM_ALIAS_FN
      COMPREPLY+=("${!knownHelpTopics[@]}")
    ;;
  esac
}
