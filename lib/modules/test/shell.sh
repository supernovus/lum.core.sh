#$< lum::test::shell
# A testing shell for lum.sh libraries
# Not meant for use by anything other than lum-core/bin/test.sh

lum::use lum::themes::default lum::use::pkg lum::help::list

lum::var -P LUM_SHELL_ \
  CTX PROMPT \
  STMT = "/" \
  HISTORY = "$HOME/.lum-core-test-history" \
  -A= STMTS \
    'c' = "lum::test::shell::ctx" \
    'h' = "lum::test::shell::help" \
    'u' = "lum::use" \
    'U' = "lum::use --reload" \
    'p' = "lum::use::pkg" \
    ';' = "history -c" \
    ':' = "shopt" \
    '~' = "eval" \
    '@' = "lum::test::shell::prompt" \
    '=' = "lum::test::shell::stmt-prefix" \
    -

## Private formatting function for our help.
lum::help::tmpl::fmt::shell() {
  repValue="${TC[item]}${LUM_SHELL_STMT}$1${TC[;]}"
}

lum::fn lum::test::shell 0 -a "$SCRIPTNAME" 1 0 -h 0 more
#$ - Shell commands
#
# $shell(q);          → Exit shell normally.
# $shell(Q);          → Exit shell, do not save history.
# $shell(h); [[topic]]  → Get help (see $see(lum::help);).
# $shell(p); <<pkg>>    → Enable the ((pkg)) (see $see(lum::use::pkg);).
# $shell(u); <<lib>>    → Use the ((lib)) library (see $see(lum::use);).
# $shell(U); <<lib>>    → Use the ((lib)) library (force reload).
# $shell(c); [[ctx]]    → Get/Set the context (see $see(shell-ctx);).
# $shell(@); <<msg>>    → Set the prompt message.
# $shell(=); [[str]]    → Get/Set the shell command prefix.
# $shell(:); <<opts>>   → Pass through to ``shopt`` command.
# $shell(~); <<cmd>>    → Run a bash command (skip context).
# $shell(;);          → Clear the shell history.
# $shell(.);          → Reload shell and all libraries.
#
# Anything else will be evaluated as a statement in the context.
# Current context: ``$var(LUM_SHELL_CTX);``
#$line();
lum::test::shell() {
  local LFR="lum::fn::run"
  local -n LT=LUM_THEME LSS=LUM_SHELL_STMT

  ## Avoid infinite loops.
  LUM_SHELL_RESTART=0
  LUM_CORE_REBOOT=0

  echo "${LT[help.header]}lum.sh testing shell${LT[end]}" 
  echo "${LT[help.syntax]}for help: ${LT[help.value]}${LSS}h${LT[end]}"

  history -r "$LUM_SHELL_HISTORY"

  while true; do 
    read -e -p "[$LUM_SHELL_PROMPT]> " line
    history -s "$line"
    case "$line" in
      "${LSS}.")
        LUM_SHELL_RESTART=1
        LUM_CORE_REBOOT=1
        break
      ;;
      "${LSS}q")
        break
      ;;
      "${LSS}Q")
        return 0
      ;;
      "${LSS}"*)
        ( lum::test::shell::stmt "$line" )
      ;;
      *)
        ( eval "$LUM_SHELL_CTX" "$line" )
      ;;
    esac
  done

  history -w "$LUM_SHELL_HISTORY"
  return 0
}

## The shell command dispatcher.
lum::test::shell::stmt() {
  local line="${1/"${LUM_SHELL_STMT}"}"
  local sid="${line:0:1}" sarg="${line:2}"
  local scmd="${LUM_SHELL_STMTS[$sid]}"
  local CE="${LT[error]}" EC="${LT[end]}"
  if [ -n "$scmd" ]; then
    $scmd "$sarg"
  else
    lum::warn "${CE}error:${EC} statement '${CE}$1${EC}' is not valid"
  fi
}

lum::fn lum::test::shell::ctx 0 -a shell-ctx 1 0
#$ - Get or set shell context
#
# If a ((ctx)) value is specified, it represents the context in which the
# shell evaluates statements. Normally this would be a shell function name,
# and possibly some leading arguments. There are a few special values:
# 
# - If one of ``0 1 2``, uses '$val(lum::fn::run); ((ctx))'.
# - If the ``-`` character, clears the context entirely.
#   With no context, the input lines are evaluated as raw bash statements.
#
# If no value is specified, this will output the current context.
#
# Default context: ``lum::fn::run 0``
# Current context: ``$var(LUM_SHELL_CTX);``
#$line();
lum::test::shell::ctx() {
  [ -z "$1" ] && echo "$LUM_SHELL_CTX" && return
  case "$1" in 
    0|1|2)
      LUM_SHELL_CTX="lum::fn::run $1"
      LUM_SHELL_PROMPT="lum:$1"
    ;;
    '-')
      LUM_SHELL_CTX=""
      LUM_SHELL_PROMPT="*"
    ;;
    *)
      LUM_SHELL_CTX="$1"
      LUM_SHELL_PROMPT="${1/" "*}"
    ;;
  esac
}

## Set the default context
lum::test::shell::ctx 0

lum::test::shell::prompt() {
  [ -z "$1" ] && echo "$LUM_SHELL_PROMPT" && return
  LUM_SHELL_PROMPT="$1"
}

lum::test::shell::help() {
  lum::help "${1:-lum::test::shell}"
}

lum::test::shell::stmt-prefix() {
  [ -z "$1" ] && echo "$LUM_SHELL_STMT" && return
  LUM_SHELL_STMT="$1"
}
