#!/usr/bin/bash

_neostow() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${cur}" in
  -)
    mapfile -t COMPREPLY < <(compgen -W "-c -p -d -r -s -r -v -h" -- "${cur}")
    return 0
    ;;
  esac

  mapfile -t COMPREPLY < <(compgen -W "edit" -- "${cur}")
}

complete -F _neostow neostow
