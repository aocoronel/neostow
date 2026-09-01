* neostow

~neostow~ is a tool that streamline the process to manage symlinks similarly to how GNU ~stow~ works, but using a ~.neostow~ file, instead. It allows more flexible symlink management, enabling the creation of symlinks from a relative source to anywhere on your computer.

This declarative nature allows to easily make reproducible and granular symlinking, unlike ~stow~. However, this project does not aims to fully replace it, but to give a declarative feature missing from it.

This tool is useful to keep files and directories organized in a single centralized place, while also having them across the system. Differently, than ~stow~, which allows you to place some files into a different target, other than the parent directory, ~neostow~ aims to further improve this functionality.

With ~neostow~ each file or directory can be symlinked to a specific part of the system, and not the project as a whole. There is not ignore file, and no need to adjust the folder layout to achieve your goals. If your ~neostow~ does not explicitly specify an operation, it won't touch a single file.

** Features

- ~ln~ *alternative*: ~ln~, but with relative path support
- *Flexible symlink creation*: Create symlinks from any relative source to any destination.
- *Per-project file*: Maintain a ~.neostow~ file per project.
- *Overwrite symlinks*: Optionally overwrite existing symlinks.
- *Remove symlinks*: Easily remove all created symlinks.
- *Preview operations*: Preview what operations would run.

** Usage

~neostow~ reads from a ~.neostow~ file in the current directory to determine which symlinks to create. In case ~.neostow~ can't be found, it looks up the directory tree, until it finds it.

The ~.neostow~ file should contain lines in the following format: ~source=destination~.

See the manpage(1) at ~FILES~ for more details. Or give at look at the [[#examples][Examples]].

#+BEGIN_SRC 
  Usage:
  	src [src] [dst] [-delete] [-dry] [-force] [-verbose] [-version]
  Flags:
  	-src:<string>  | Source file, or neostow file
  	-dst:<string>  | Destination
  	               |
  	-delete        | Delete symlinks
  	-dry           | Dry mode
  	-force         | Force operation
  	-verbose       | Enable dubugging
  	-version       | Print version
  Examples:
  ./neostow .neostow ; loads .neostow file
  ./neostow          ; loads .neostow file
  ./neostow README.md ~/todo ; symlinks README.md to ~/todo
#+END_SRC

*** Environment Variables

- ~NEOSTOW_FILE~: replaces the default file, if none is provided

*** Configuration File

The ~.neostow~ file should be placed in the root of your project directory.

**** Examples

Example ~.neostow~ file:

#+BEGIN_SRC 
config/myconfig.txt=/home/username/.config/myconfig/ ; links myconfig.txt to ~/.config/myconfig/
scripts/myscript.sh=/home/username/bin/myscript/     ; links myscript.sh to ~/bin/myscrypt/
myfile=$HOME/Downloads                               ; links myfile to ~/Downloads
#+END_SRC

The left side paths are relative to the current directory where the ~.neostow~ file is found.

Case ~NEOSTOW_FILE~ is defined, when using ~neostow~ as a ~ln~ replacement, it will automatically add the symlink entry to the file.

** Notes

This program was only tested in a Linux machine.

** License

This repository is licensed under the MIT License, a very permissive license that allows you to use, modify, copy, distribute and more.
