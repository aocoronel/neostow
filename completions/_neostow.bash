#!/usr/bin/env bash

# This file was manually written

_FILE() {
  ls
}

_complete() {
  mapfile -t COMPREPLY < <(compgen -W "$@" -- "${cur}")
  return 0
}

_neostow() {
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  case "${cur}" in
  -*)
    _complete " --file -f --debug -D --dry -d --overwrite -o --help -h --force -F --verbose -V --version -v"
    return 0
    ;;
  esac
  case "${prev}" in
  -f | --file)
    _complete "$(_FILE)"
    return 0
    ;;
  esac
  _complete "edit delete"
  return 0
}

complete -F _neostow neostow
