use std::fmt;
use std::io::{self, Write};

const COLOR_RED: &str = "\x1b[91m";
const COLOR_YELLOW: &str = "\x1b[33m";
const COLOR_GREEN: &str = "\x1b[38;5;47m";
const COLOR_BLUE: &str = "\x1b[38;5;75m";
const COLOR_RESET: &str = "\x1b[0m";

#[derive(Debug)]
pub enum LogLevel {
    Fatal,
    Error,
    Warn,
    Info,
    Debug,
}

pub fn printfc_func(level: LogLevel, fmt: fmt::Arguments) -> io::Result<()> {
    let (color, label, mut out): (&str, &str, Box<dyn Write>) = match level {
        LogLevel::Fatal => (COLOR_RED, "FATAL", Box::new(io::stderr())),
        LogLevel::Error => (COLOR_RED, "ERROR", Box::new(io::stderr())),
        LogLevel::Warn => (COLOR_YELLOW, "WARNING", Box::new(io::stdout())),
        LogLevel::Info => (COLOR_GREEN, "INFO", Box::new(io::stdout())),
        LogLevel::Debug => (COLOR_BLUE, "DEBUG", Box::new(io::stdout())),
    };

    write!(out, "{}[{}]:{} ", color, label, COLOR_RESET)?;
    write!(out, "{}\n", fmt)?;
    out.flush()?;
    Ok(())
}

#[macro_export] macro_rules! printfc {
    ($level:expr, $($arg:tt)*) => {
        printfc_func($level, format_args!($($arg)*)).unwrap();
    };
}
