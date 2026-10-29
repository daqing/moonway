///|
fn cli_version() -> String {
  "v0.11.9"
}

///|
/// Version shown by `moonway --version`. Reads the manifest when running
/// from the source tree; an installed binary resolves `"../moon.mod"`
/// against the caller's CWD, so fall back to the pinned `cli_version()`.
pub fn version() -> String {
  let v = @parse-version.Version::parse("../moon.mod") catch {
    _ => cli_version()
  }
  if v.has_prefix("v") {
    "moonway \{v}"
  } else {
    "moonway v\{v}"
  }
}

///|
pub fn help_text() -> String {
  let lines = [
    "moonway \{cli_version()} — the road to the moon",
    "",
    "Usage: moonway <command> [options]",
    "",
    "Commands:",
    "  moonway new <name|path>                     create a new moonway app",
    "  moonway generate scaffold <Model> f:type    scaffold a model, handlers",
    "                                              and migration",
    "  moonway console [--db <path>]               interactive database console",
    "  moonway --version                           print the version",
    "  moonway --help                              print this help",
    "",
    "Field types: string, text, int, bool, float",
  ]
  join_lines(lines)
}

///|
fn join_lines(lines : Array[String]) -> String {
  let mut out = ""
  for i, line in lines {
    if i > 0 {
      out = out + "\n"
    }
    out = out + line
  }
  out
}

///|
/// Execute a parsed command.
pub fn run(argv : Array[String]) -> Unit {
  match parse(argv) {
    Help => println(help_text())
    Version => println(version())
    New(name, dir) => execute_new(name, dir.unwrap_or("."))
    GenerateScaffold(model, fields) => execute_scaffold(model, fields)
    Console(db_path) => run_console(db_path)
    Invalid(message) => eprintln("moonway: \{message}")
  }
}
