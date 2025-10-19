use std::env;
use std::fmt;
use std::fs;
use std::io::{self, BufRead, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, exit};

#[cfg(unix)]
use std::os::unix::fs::symlink;

#[cfg(windows)]
use std::os::windows::fs::{symlink_dir, symlink_file};

enum Mode {
    Create,
    Overwrite,
    Delete,
}

struct Config {
    file: PathBuf,
    basedir: PathBuf,
    mode: Mode,
    verbose: bool,
    force: bool,
    dry: bool,
    debug: bool,
}

const COLOR_RED: &str = "\x1b[91m";
// const COLOR_YELLOW: &str = "\x1b[33m";
const COLOR_GREEN: &str = "\x1b[38;5;47m";
const COLOR_BLUE: &str = "\x1b[38;5;75m";
const COLOR_RESET: &str = "\x1b[0m";

#[derive(Debug)]
enum LogLevel {
    Fatal,
    Error,
    // Warn,
    Info,
    Debug,
}

fn printfc_func(level: LogLevel, fmt: fmt::Arguments) -> io::Result<()> {
    let (color, label, mut out): (&str, &str, Box<dyn Write>) = match level {
        LogLevel::Fatal => (COLOR_RED, "FATAL", Box::new(io::stderr())),
        LogLevel::Error => (COLOR_RED, "ERROR", Box::new(io::stderr())),
        // LogLevel::Warn => (COLOR_YELLOW, "WARNING", Box::new(io::stdout())),
        LogLevel::Info => (COLOR_GREEN, "INFO", Box::new(io::stdout())),
        LogLevel::Debug => (COLOR_BLUE, "DEBUG", Box::new(io::stdout())),
    };

    write!(out, "{}[{}]:{} ", color, label, COLOR_RESET)?;
    write!(out, "{}\n", fmt)?;
    out.flush()?;
    Ok(())
}

macro_rules! printfc {
    ($level:expr, $($arg:tt)*) => {
        printfc_func($level, format_args!($($arg)*)).unwrap();
    };
}

fn help() {
    println!(
        "\
neostow | The Declarative GNU Stow

Usage:  neostow [OPTIONS] <COMMAND>

Commands:
  delete
          Delete symlinks
  edit
          Edit the neostow file

Options:
  -F, --force
          Skip prompt dialogs
  -V, --verbose
          Enable verbosity
  -d, --dry
          Describe potential operations
  -f, --file <FILE>
          Load an alternative neostow file
  -h, --help
          Displays this message and exits
  -o, --overwrite
          Overwrite existing symlinks
  -v, --version
          Displays program version"
    );
}

fn create_symlink(src: &Path, dest: &Path, is_dir: bool, cfg: &Config) -> io::Result<bool> {
    if dest.exists() && !dest.symlink_metadata()?.file_type().is_symlink() {
        if let Mode::Overwrite = cfg.mode {
            let do_prompt = run_diff(src, dest, is_dir)?;

            if do_prompt && !cfg.force {
                if !prompt_user(&format!(
                    "Destination '{}' exists and is not a symlink. Overwrite?",
                    dest.display()
                ))? {
                    return Ok(false);
                }
            }
        }
    }

    match cfg.mode {
        Mode::Delete => {
            if cfg.dry {
                printfc!(LogLevel::Info, "Would remove {}", dest.display());
                return Ok(false);
            }
            if dest.exists() {
                if dest.is_dir() {
                    fs::remove_dir_all(dest)?;
                } else {
                    fs::remove_file(dest)?;
                }
            }
        }
        Mode::Overwrite => {
            if cfg.dry {
                printfc!(LogLevel::Info, "Would remove {}", dest.display());
                println!("{} → {}", src.display(), dest.display());
                return Ok(false);
            }
            if dest.exists() {
                if dest.is_dir() {
                    fs::remove_dir_all(dest)?;
                } else {
                    fs::remove_file(dest)?;
                }
            }
            #[cfg(unix)]
            symlink(src, dest)?;
            #[cfg(windows)]
            {
                if is_dir {
                    symlink_dir(src, dest)?;
                } else {
                    symlink_file(src, dest)?;
                }
            }
        }
        Mode::Create => {
            if cfg.dry {
                println!("{} → {}", src.display(), dest.display());
                return Ok(false);
            }
            #[cfg(unix)]
            symlink(src, dest)?;
            #[cfg(windows)]
            {
                if is_dir {
                    symlink_dir(src, dest)?;
                } else {
                    symlink_file(src, dest)?;
                }
            }
        }
    }

    Ok(true)
}

fn expand_path(raw: &str) -> PathBuf {
    let replaced = std::env::vars().fold(raw.to_string(), |acc, (key, val)| {
        acc.replace(&format!("${}", key), &val)
    });

    if replaced.starts_with("~") {
        if let Some(home) = env::var("HOME").ok() {
            return PathBuf::from(replaced.replacen("~", &home, 1));
        }
    }

    PathBuf::from(replaced)
}

fn process_line(line: &str, cfg: &Config, operations: &mut i32) -> io::Result<()> {
    let mut line = line.trim();
    if line.is_empty() || line.starts_with('#') {
        return Ok(());
    }

    if let Some(comment_start) = line.find('#') {
        if comment_start > 0 {
            line = &line[..comment_start].trim();
        }
    }

    if line.is_empty() {
        return Ok(());
    }

    let parts: Vec<&str> = line.splitn(2, '=').map(str::trim).collect();
    if parts.len() != 2 {
        return Ok(());
    }

    let src = cfg.basedir.join(parts[0]);

    if cfg.debug {
        printfc!(LogLevel::Debug, "Source file: {}", src.display());
    }

    let dest_base = expand_path(parts[1]);

    if cfg.debug {
        printfc!(LogLevel::Debug, "Destination: {}", dest_base.display());
    }

    if !src.exists() {
        if cfg.verbose {
            printfc!(LogLevel::Error, "Source {:?} not found", src);
        }
        return Ok(());
    }

    let is_dir = src.is_dir();

    let dest = dest_base.join(src.file_name().unwrap());

    if let Some(parent) = dest.parent() {
        if !cfg.dry {
            fs::create_dir_all(parent)?;
        }
    }

    let success = create_symlink(&src, &dest, is_dir, &cfg)?;

    if success {
        *operations += 1;
        if cfg.verbose {
            let mode_str = match cfg.mode {
                Mode::Create => "Created symlink",
                Mode::Overwrite => "Overwritten symlink",
                Mode::Delete => "Deleted symlink",
            };
            println!(
                "{}",
                &format!("{mode_str}: {} → {}", dest.display(), src.display())
            );
        }
    }

    Ok(())
}

fn run(cfg: &Config, operations: &mut i32) -> io::Result<()> {
    let file = fs::File::open(&cfg.file)?;
    let reader = io::BufReader::new(file);
    let mut linenum = 0;

    for line in reader.lines() {
        linenum += 1;
        if let Err(err) = process_line(&line?, &cfg, operations) {
            printfc!(LogLevel::Error, "{}:{}: {err}", cfg.file.display(), linenum);
        }
    }

    Ok(())
}

fn edit_file(path: &Path) -> io::Result<()> {
    let editor = env::var("EDITOR").unwrap_or_else(|_| "vim".into());
    let status = Command::new(editor).arg(path).status()?;
    if !status.success() {
        return Err(io::Error::new(io::ErrorKind::Other, "Editor failed"));
    }
    Ok(())
}

fn prompt_user(prompt: &str) -> io::Result<bool> {
    println!("{prompt} [y/N] ");
    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    Ok(matches!(input.trim().to_lowercase().as_str(), "y" | "yes"))
}

fn run_diff(src: &Path, dest: &Path, is_dir: bool) -> io::Result<bool> {
    let mut cmd = Command::new("diff");
    if is_dir {
        cmd.arg("-r");
    }
    let status = cmd.arg("-u").arg(src).arg(dest).status()?;
    if !status.success() {
        println!("Files differ.");
        Ok(true)
    } else {
        println!("Files are identical.");
        Ok(false)
    }
}

fn version() {
    println!("1.0.0");
}

fn main() -> io::Result<()> {
    let mut args = env::args().skip(1);
    let mut cfg = Config {
        file: env::current_dir()?.join(".neostow"),
        basedir: env::current_dir()?,
        mode: Mode::Create,
        verbose: false,
        force: false,
        dry: false,
        debug: false,
    };
    let mut operations: i32 = 0;
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "delete" => cfg.mode = Mode::Delete,
            "-o" | "--overwrite" => cfg.mode = Mode::Overwrite,
            "-V" | "--verbose" => cfg.verbose = true,
            "-v" | "--version" => {
                version();
                return Ok(());
            }
            "-D" | "--debug" => cfg.debug = true,
            "-d" | "--dry" => cfg.dry = true,
            "-F" | "--force" => {
                cfg.force = true;
            }
            "-h" | "--help" => {
                help();
                return Ok(());
            }
            "-f" | "--file" => {
                if let Some(path) = args.next() {
                    cfg.file = PathBuf::from(path);
                    cfg.basedir = cfg
                        .file
                        .parent()
                        .map(PathBuf::from)
                        .unwrap_or_else(|| PathBuf::from("."));
                }
            }
            "edit" => {
                return edit_file(&cfg.file);
            }
            _ => {
                printfc!(LogLevel::Fatal, "Unknown argument: {arg}");
                exit(1);
            }
        }
    }

    if !cfg.file.exists() {
        printfc!(LogLevel::Fatal, "{:?} not found", cfg.file);
        exit(1);
    }

    let cfg = cfg;
    let result = run(&cfg, &mut operations);
    println!("{} operations were performed.", operations);
    result
}
