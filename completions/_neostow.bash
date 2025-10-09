#!/usr/bin/env bash
_SHELL() {
  echo -e 'bash\nzsh'
}
_FILE() {
  ls
}
_neostow() {
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  case "${cur}" in
  -*)
    mapfile -t COMPREPLY < <(compgen -W " --file -f --debug -D --dry -d --overwrite -o --help -h --force -F --verbose -V --version -v" -- "${cur}")
    return 0
    ;;
  esac
  case "${prev}" in
  -f | --file)
    mapfile -t COMPREPLY < <(compgen -W "$(_FILE)" -- "${cur}")
    return 0
    ;;
  esac
  mapfile -t COMPREPLY < <(compgen -W "edit delete" -- "${cur}")
  return 0
}
complete -F _neostow neostow
