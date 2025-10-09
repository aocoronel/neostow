#compdef neostow

_neostow() {
  local -a subcommands

  subcommands=(
    "edit:Edit the neostow file"
    "delete:Delete symlinks"
  )

  _arguments -C \
    '1:command:->subcmds' \
    '--file=[Load an alternative neostow file]:FILE:_neostow_get_FILE' \
    '-f[Load an alternative neostow file]:FILE:_neostow_get_FILE' \
    '--debug=[Enables debug verbosity]' \
    '-D[Enables debug verbosity]' \
    '--dry=[Describe potential operations]' \
    '-d[Describe potential operations]' \
    '--overwrite=[Overwrite existing symlinks]' \
    '-o[Overwrite existing symlinks]' \
    '--help=[Displays this message and exits]' \
    '-h[Displays this message and exits]' \
    '--force=[Skip prompt dialogs]' \
    '-F[Skip prompt dialogs]' \
    '--verbose=[Enable verbosity]' \
    '-V[Enable verbosity]' \
    '--version=[Displays program version]' \
    '-v[Displays program version]' \
    '*::args:->command_args'

  case $state in
    subcmds)
      _describe 'command' subcommands
      return
      ;;
    command_args)
      case $words[1] in
        -f | --file)
          _arguments \
            '*:FILE:_neostow_get_FILE' \
          return
          ;;
      esac
      ;;
  esac
}


_neostow_get_FILE() {
  local results
  results=(${(f)"$(ls 2>/dev/null)"})
  compadd -Q -a results
}

compdef _neostow neostow
