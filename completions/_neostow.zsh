#compdef neostow

# This file was manually written

_neostow() {
    _arguments -C \
    '1:command:->args' \
	'-src=[Source file, or neostow file]:FILE:_neostow_get_FILE' \
	'-dst=[Destination]:FILE:_neostow_get_FILE' \
	'-delete=[Delete symlinks]' \
	'-dry=[Dry mode]' \
	'-force=[Force operation]' \
	'-verbose=[Enable dubugging]' \
	'-version=[Print version]'
  
  case $state in
    args)
      _arguments '*:FILE:_neostow_get_FILE'
      return
    ;;
  esac
}

_neostow_get_FILE() {
  local results
  results=(${(f)"$(ls 2>/dev/null)"})
  compadd -Q -a results
}

compdef _neostow neostow
