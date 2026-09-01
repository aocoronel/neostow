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
    _complete " -src -dst -delete -dry -force -verbose -version"
    return 0
    ;;
  esac
  _complete "$(_FILE)"
  return 0
}

complete -F _neostow neostow
