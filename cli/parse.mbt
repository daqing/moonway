///|
/// A parsed moonway CLI invocation.
pub(all) enum Command {
  New(String, String?)
  GenerateScaffold(String, Array[String])
  Console(String)
  Help
  Version
  Invalid(String)
} derive(Eq, Debug)

///|
pub extend Command with Eq::{equal, not_equal}

///|
pub extend Command with @debug.Debug::{to_repr}

///|
/// Parse a full argv (including the program name at index 0).
pub fn parse(argv : Array[String]) -> Command {
  if argv.length() < 2 {
    return Help
  }
  let command = argv[1]
  if command == "--help" || command == "-h" || command == "help" {
    return Help
  }
  if command == "--version" {
    return Version
  }
  if command == "new" {
    if argv.length() < 3 {
      return Invalid("usage: moonway new <name> [--dir <dir>]")
    }
    let name = argv[2]
    let mut dir : String? = None
    for i in 3..<argv.length() {
      if argv[i] == "--dir" && i + 1 < argv.length() {
        dir = Some(argv[i + 1])
      }
    }
    return New(name, dir)
  }
  if command == "console" {
    if argv.length() == 3 {
      return Console("app.db")
    }
    if argv.length() == 4 && argv[2] == "--db" {
      return Console(argv[3])
    }
    return Invalid("usage: moonway console [--db <path>]")
  }
  if command == "generate" {
    return parse_generate(argv)
  }
  Invalid("unknown command: \{command} (try moonway --help)")
}

///|
fn parse_generate(argv : Array[String]) -> Command {
  if argv.length() < 3 || argv[2] != "scaffold" {
    return Invalid("usage: moonway generate scaffold <Model> [field:type ...]")
  }
  if argv.length() < 4 {
    return Invalid("usage: moonway generate scaffold <Model> [field:type ...]")
  }
  let model = argv[3]
  let fields = []
  for i in 4..<argv.length() {
    fields.push(argv[i])
  }
  GenerateScaffold(model, fields)
}
