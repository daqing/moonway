///|
let cli_version = "0.1.0"

///|
pub fn version() -> String {
  "moonway \{cli_version}"
}

///|
pub fn help_text() -> String {
  let lines = [
    "moonway \{cli_version} — the road to the moon",
    "",
    "Usage: moonway <command> [options]",
    "",
    "Commands:",
    "  moonway new <name>                          create a new moonway app",
    "  moonway generate scaffold <Model> f:type    scaffold a model, handlers",
    "                                              and migration",
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
    Invalid(message) => eprintln("moonway: \{message}")
  }
}
