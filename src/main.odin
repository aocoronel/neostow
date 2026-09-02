
package sln

import "base:runtime"
import "core:encoding/ini"
import "core:flags"
import "core:fmt"
import "core:hash"
import "core:log"
import "core:os"
import "core:strings"

VERSION :: "0.2.0"

Error :: os.Error

Option :: struct {
	src:     string `args:"pos=0" usage:"Source file, or neostow file"`,
	dst:     string `args:"pos=1" usage:"Destination"`,
	delete:  bool `usage:"Delete symlinks"`,
	dry:     bool `usage:"Dry mode"`,
	force:   bool `usage:"Force operation"`,
	verbose: bool `usage:"Enable dubugging"`,
	version: bool `usage:"Print version"`,
}

Codepath :: enum u32 {
	Linker = 0,
	Dotfile,
}

Flags :: enum {
	None = 0,
	Delete,
	Force,
	Dry,
	Verbose,
}

exists :: proc(path: string) -> Error {
	exist := os.exists(path)
	if !exist {
		return os.General_Error.Not_Exist
	}
	return nil
}

@(require_results)
open :: proc(
	name: string,
	flags := os.File_Flags{.Read},
	perm := os.Permissions_Default_File,
) -> (
	^os.File,
	Error,
) {
	return os.open(name, flags, perm)
}

remove :: proc(path: string, flags: bit_set[Flags] = nil) -> Error {
	if .Dry in flags {
		if exists(path) == nil do fmt.eprintln("removed:", path)
	} else {
		err := os.remove(path)
		if err != nil && err != .Exist do return err
		if .Verbose in flags do fmt.eprintln("removed:", path)
	}
	return nil
}

ln :: proc(src, dst: string, flags: bit_set[Flags] = nil) -> (err: Error) {
	absolute_src := os.get_absolute_path(src, context.allocator) or_return
	defer delete(absolute_src)

	verbose: bool = .Verbose in flags

	if .Force in flags {
		// coreutils 'ln' removes the file no matter what
		remove(dst, flags)
	}

	if !(.Dry in flags) {
		os.make_directory_all(os.dir(dst))
		err = os.symlink(absolute_src, dst)
		if err != nil do return
	}
	if verbose do fmt.eprintln(src, "->", dst)

	return
}

expand_env :: proc(
	path: string,
	allocator: runtime.Allocator,
) -> (
	string,
	runtime.Allocator_Error,
) {
	result := strings.clone(path, allocator)

	for {
		env_begin := strings.index(result, "$")
		if env_begin == -1 {
			break
		}

		env_end := env_begin + 1
		for env_end < len(result) {
			c := result[env_end]
			if !((c >= 'a' && c <= 'z') ||
				   (c >= 'A' && c <= 'Z') ||
				   (c >= '0' && c <= '9') ||
				   c == '_') {
				break
			}
			env_end += 1
		}

		if env_end == env_begin + 1 {
			break
		}

		name := result[env_begin + 1:env_end]

		value := os.get_env(name, allocator)

		result, _ = strings.replace(
			result,
			result[env_begin:env_end],
			value,
			env_end - env_begin,
			allocator,
		)

	}

	return result, nil
}

dir :: proc(path: string) -> (dir_name: string, err: Error) {
	dir_name = os.dir(path)
	if len(dir_name) == 0 {
		dir_name = os.getwd(context.allocator) or_return
	}
	return
}

Iterator :: struct {
	it:   ini.Iterator,
	line: int,
}

// stolen from core:encoding/ini
// Added 'no_value' to signal a line without '='
// Added 'line' to Iterator, for better user friendly errors
iterate :: proc(iterator: ^Iterator) -> (key, value: string, ok: bool, no_value: bool) {
	it := &iterator.it
	for line_ in strings.split_lines_iterator(&it._src) {
		iterator.line += 1
		line := strings.trim_space(line_)

		if len(line) == 0 {
			continue
		}

		if line[0] == '[' {
			end_idx := strings.index_byte(line, ']')
			if end_idx < 0 {
				end_idx = len(line)
			}
			it.section = line[1:end_idx]
			continue
		}

		if it.options.comment != "" && strings.has_prefix(line, it.options.comment) {
			continue
		}

		equal := strings.index(line, " =") // check for things keys that `ctrl+= = zoom_in`
		quote := strings.index_byte(line, '"')
		if equal < 0 || quote > 0 && quote < equal {
			equal = strings.index_byte(line, '=')
			if equal < 0 {
				key = strings.trim_space(line)
				ok = true
				no_value = true
				return
			}
		} else {
			equal += 1
		}

		key = strings.trim_space(line[:equal])
		value = strings.trim_space(line[equal + 1:])
		ok = true
		return
	}

	it.section = ""
	return
}

dotfile :: proc(config: string, flags: bit_set[Flags] = nil) -> Error {
	contents := os.read_entire_file(config, context.temp_allocator) or_return

	ini_iterator := ini.iterator_from_string(string(contents))

	it := Iterator {
		it = ini_iterator,
	}

	current_hash: u32
	section: string

	verbose: bool = .Verbose in flags
	delete: bool = .Delete in flags
	dry: bool = .Dry in flags

	symlink :: proc(
		src, dst: string,
		flags: bit_set[Flags] = nil,
	) -> (
		source_error: bool = true,
		err: Error,
	) {
		exists(src) or_return
		source_error = false
		err = ln(src, dst, flags)
		return
	}

	last_rune :: proc(s: string, r: rune) -> bool {
		return rune(s[len(s) - 1]) == r
	}

	for {
		key, value, ok, no_value := iterate(&it)
		if !ok do break

		src, dst, expanded_value, expanded_key: string

		expanded_key = expand_env(key, context.temp_allocator) or_return

		if no_value {
			expanded_value = "."
		} else {
			expanded_value = expand_env(value, context.temp_allocator) or_return
		}

		// default section
		if len(it.it.section) == 0 {
			if no_value {
				log.errorf("default section doesn't support entries without values")
				continue
			}
			dst = expanded_value
			src = expanded_key
		} else {
			src = expanded_key

			// hashing so we don't have to expand section every iteration
			new_hash := hash.djb2(transmute([]byte)it.it.section[:])
			if current_hash != new_hash {
				current_hash = new_hash
				section = expand_env(it.it.section, context.temp_allocator) or_return
			}
			if expanded_value == "." {
				dst = strings.concatenate({section, "/"}, context.temp_allocator) or_return
			} else {
				dst = strings.concatenate(
					{section, "/", expanded_value},
					context.temp_allocator,
				) or_return
			}
		}
		if last_rune(dst, '/') do dst = strings.concatenate({dst, src}, context.temp_allocator)
		if delete {
			err := remove(dst, flags)
			if err != nil {
				log.errorf("[%s:%d]: %s: %s", config, it.line, os.error_string(err), dst)
			}
		} else {
			source_error, err := symlink(src, dst, flags)
			if err != nil {
				if source_error {
					log.errorf("[%s:%d]: %s: %s", config, it.line, os.error_string(err), src)
				} else {
					log.errorf("[%s:%d]: %s: %s", config, it.line, os.error_string(err), dst)
				}
			}
		}

	}

	return nil
}

exit_error :: proc(args: ..any, sep := " ", location := #caller_location) -> ! {
	log.error(args, sep, location)
	os.exit(1)
}

is_nil :: proc(s: string) -> bool {
	return len(s) == 0
}

change_dir :: proc(src: string) -> Error {
	cwd := os.getwd(context.allocator) or_return
	defer delete(cwd)

	target := src

	for {
		candidate := strings.concatenate({cwd, "/", target}, context.allocator) or_return
		fmt.println(candidate)
		found := exists(candidate) == nil
		delete(candidate)

		if found {
			fmt.println("changing to:", cwd)
			os.change_directory(cwd)
			return nil
		}

		parent := dir(cwd) or_return

		if parent == cwd {
			break
		}

		cwd = parent
	}

	return .Not_Exist
}

add_entry :: proc(env: string, src, dst: string) -> Error {
	contents: []byte
	defer delete(contents)

	{
		file, err := open(env, {.Read})
		if err == nil {
			contents = os.read_entire_file(file, context.allocator) or_return
		}
	}

	it := ini.iterator_from_string(string(contents))

	for {
		key, value, ok := ini.iterate(&it)
		// only default
		if !ok || len(it.section) != 0 do break
		if key == src && value == dst do return nil
	}

	file := open(env, {.Write, .Create, .Trunc}) or_return
	entry := fmt.tprintf("%s=%s", src, dst, newline = true)

	_ = os.write(file, transmute([]byte)entry) or_return
	_ = os.write(file, contents) or_return

	return nil
}

main :: proc() {
	neostow_env: string = os.get_env("NEOSTOW_FILE", context.allocator)
	defer delete(neostow_env)
	has_env: bool = !is_nil(neostow_env)

	codepath: Codepath

	opt: Option
	flags.parse_or_exit(&opt, os.args, .Odin)

	if opt.version {
		fmt.println(VERSION)
		return
	}

	log.Level_Headers = {
		0 ..< 10 = "debug: ",
		10 ..< 20 = "info: ",
		20 ..< 30 = "warn: ",
		30 ..< 40 = "error: ",
		40 ..< 50 = "fatal: ",
	}

	context.logger = log.create_console_logger(opt = {.Level, .Terminal_Color})
	defer log.destroy_console_logger(context.logger)

	if is_nil(opt.dst) {
		codepath = .Dotfile
		if is_nil(opt.src) do opt.src = neostow_env if has_env else ".neostow"
		// This replaces just
		change_dir_err := change_dir(opt.src)
		switch change_dir_err {
		case nil:
			break
		case:
			exit_error(change_dir_err)
		case .Not_Exist:
			log.errorf("could not find '%s' in current directory or any parent", opt.src)
			os.exit(1)
		}
	}

	flags: bit_set[Flags]
	if opt.force do flags += {.Force}
	if opt.verbose do flags += {.Verbose}
	if opt.dry do flags += {.Dry}
	if opt.delete do flags += {.Delete}

	err: Error
	finfo: os.File_Info
	finfo, err = os.stat(opt.src, context.temp_allocator)
	if err != nil do exit_error(err)

	type := finfo.type

	switch codepath {
	case .Linker:
		err = ln(opt.src, opt.dst, flags)
		if err == nil {
			// add entry, only when env is set
			if has_env {
				err := add_entry(neostow_env, opt.src, opt.dst)
				if err != nil do exit_error(err)
			}
		}
	case .Dotfile:
		err = dotfile(opt.src, flags)
	}

	if err != nil do exit_error(err)

	return
}
