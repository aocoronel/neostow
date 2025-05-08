# Neostow

Neostow is a shell script project that aims to reinvent the wheel... Rewrite the functionality of GNU Stow. It allows for more flexible symlink management, enabling the creation of symlinks from anywhere to anywhere on your computer. Unlike GNU Stow, Neostow does not rely on a 'package' structure, providing more freedom in managing your symlinks through a configuration file.

The declarative nature of Neostow allows to easily make reproducible and granular symlinking, unlike GNU Stow. However, this project does not aims to fully replace GNU Stow, but to give a declarative feature missing from it.

## Features

- **Flexible Symlink Creation**: Create symlinks from any source to any destination.
- **Per-Project Configuration**: Maintain a `.neostow` configuration file per project.
- **Overwrite Symlinks**: Optionally overwrite existing symlinks.
- **Remove Symlinks**: Easily remove all created symlinks.
- **Get files from the web**: Configure links to files in the web to be automatically downloaded to the right location (WIP).

## Installation

```bash
# 1. Clone the Repository
git clone https://github.com/yourusername/neostow.git
cd neostow
# 2. Make the Script Executable
chmod +x neostow
# 3. Move the Script to a Directory in Your PATH
mv neostow $HOME/.local/bin
# OR
# sudo mv neostow /usr/local/bin/
```

## Usage

Neostow reads from a `.neostow` file in the current directory to determine which symlinks to create. The `.neostow` file should contain lines in the format `source=destination`.

### Commands

```
Neostow
Usage: neostow [flag] [command]
Available flags:
-d                       - Remove all symlinks
-h                       - Displays this message and exits
-r                       - Overwrite symlinks
-s                       - Skip Wget Download
-t <absolute_path>       - Target a different project directory
-v                       - Enable verbose
Available commands:
edit                   - Edit the .neostow file
help                   - Displays this message and exits
```

### Configuration File

The `.neostow` file should be placed in the root of your project directory. Each line in the file should specify a symlink in the format `source=destination`.

#### Examples

Example `.neostow` file:

```
config/myconfig=/home/username/.config/myconfig/
scripts/myscript.sh=/home/username/bin/myscript/
```

##### Declaring Files

```
forg.conf=$HOME/.local/share/
```

The `forg.conf` file will be added as: `/home/username/.local/share/forg.conf`

##### Declaring Folders

```
.local/bin/=$HOME/.local/
.config/alacritty/=$HOME/.config/
```

The `.local` directory will be added as: `/home/username/.local/bin/`
The `.config` directory will be added as: `/home/username/.config/alacritty/`

##### Declaring Links

> [!NOTE]
> Currently files from the web are not added as symlinks.

```
https://raw.githubusercontent.com/janpstrunn/neostow/refs/heads/main/README.md=$HOME/.cache/
```

The `README.md` file will be added as: `/home/username/.cache/README.md`

## Integrations

### [Just](https://github.com/casey/just)

`just` is a handy way to save and run `neostow` commands from any directory within the project.

In or `justfile`, you may create a recipe like this:

```just
# Neostow: Skip wget, verbose and overwrite
neostow:
  neostow -s -v -r
```

Then, from any child directory where this `justfile` was placed, you can just run `just neostow`, and it will run the configured recipe.

## License

This repository is licensed under the MIT License, a very permissive license that allows you to use, modify, copy, distribute and more.
