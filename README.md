# Neostow

Neostow is a shell script project that aims to reinvent the wheel... Rewrite the functionality of GNU Stow. It allows for more flexible symlink management, enabling the creation of symlinks from anywhere to anywhere on your computer. Unlike GNU Stow, Neostow does not rely on a 'package' structure, providing more freedom in managing your symlinks through a configuration file.

The declarative nature of Neostow allows to easily make reproducible and granular symlinking, unlike GNU Stow. However, this project does not aims to fully replace GNU Stow, but to give a declarative feature missing from it.

## Features

- **Flexible Symlink Creation**: Create symlinks from any source to any destination.
- **Per-Project Configuration**: Maintain a `.neostow` configuration file per project.
- **Overwrite Symlinks**: Optionally overwrite existing symlinks.
- **Remove Symlinks**: Easily remove all created symlinks.
- **Adopt Existing Files**: Adopt already existing files or directories into the symlink management.

## Installation

1. **Clone the Repository**:

    ```sh
    git clone https://github.com/yourusername/neostow.git
    cd neostow
    ```

2. **Make the Script Executable**:

    ```sh
    chmod +x neostow
    ```

3. **Move the Script to a Directory in Your PATH**:
    ```sh
    sudo mv neostow /usr/local/bin/
    ```

## Usage

Neostow reads from a `.neostow` file in the current directory to determine which symlinks to create. The `.neostow` file should contain lines in the format `source=destination`.

### Commands

- **Create Symlinks**:

    ```sh
    neostow
    ```

- **Overwrite Symlinks**:

    ```sh
    neostow -r
    ```

- **Remove All Symlinks**:

    ```sh
    neostow -d
    ```

- **Use a different project directory**

```bash
   neostow stow -t
```

- **Adopt Existing File or Directory**:

    ```sh
    neostow adopt
    ```

- **Display Help Message**:
    ```sh
    neostow help
    ```

### Flags

- `-d`: Remove all created symlinks.
- `-h`: Display the help message and exit.
- `-r`: Overwrite existing symlinks.
- `-t`: Change project directory.

## Configuration File

The `.neostow` file should be placed in the root of your project directory. Each line in the file should specify a symlink in the format `source=destination`.

Example `.neostow` file:

```
config/myconfig=~/.config/myconfig
scripts/myscript.sh=~/bin/myscript
```

## License

This repository is licensed under the MIT License, a very permissive license that allows you to use, modify, copy, distribute and more.
