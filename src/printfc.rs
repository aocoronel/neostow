use std::{
    fmt,
    io::{self, Write},
};

static COLOR_RED: &str = "\x1b[91m";
static COLOR_YELLOW: &str = "\x1b[33m";
static COLOR_GREEN: &str = "\x1b[38;5;47m";
static COLOR_BLUE: &str = "\x1b[38;5;75m";
static COLOR_RESET: &str = "\x1b[0m";

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

#[macro_export]
macro_rules! fatalf {
    ($($arg:tt)*) => {
        printfc_func(LogLevel::Fatal, format_args!($($arg)*)).unwrap();
    };
}

#[macro_export]
macro_rules! warnf {
    ($($arg:tt)*) => {
        printfc_func(LogLevel::Warn, format_args!($($arg)*)).unwrap();
    };
}

#[macro_export]
macro_rules! infof {
    ($($arg:tt)*) => {
        printfc_func(LogLevel::Info, format_args!($($arg)*)).unwrap();
    };
}

#[macro_export]
macro_rules! errorf {
    ($($arg:tt)*) => {
        printfc_func(LogLevel::Error, format_args!($($arg)*)).unwrap();
    };
}

#[macro_export]
macro_rules! debugf {
    ($($arg:tt)*) => {
        printfc_func(LogLevel::Debug, format_args!($($arg)*)).unwrap();
    };
}
