#compdef neostow

_neostow() {
  local -a subcommands edit_options

  subcommands=(
    "edit:Edit configuration file"
  )

  _arguments -C \
    '1:command:->subcmds' \
    '-d=[Remove all symlinks]' \
    '-c=[Use different configuration file]' \
    '-r=[Overwrite symlinks]' \
    '-v[Display command version]' \
    '-p[Set parallels]' \
    '-h[Display help message]' \
    '--help[Display help message]' \
    '*::args:->command_args'

  case $state in
  subcmds)
    _describe 'command' subcommands
    return
    ;;
  esac
}

compdef _neostow neostow
