///|
/// `moonway console [--db <path>]` — an interactive terminal for the
/// project's SQLite database (default app.db). Tables are discovered from
/// the database itself, so no compiled-in models are required.
pub(all) enum ConsoleCommand {
  TableAll(String)
  TableCount(String)
  TableFind(String, Int)
  TableInsert(String, Json)
  DotHelp
  DotTables
  DotQuit
  Blank
  Invalid(String)
} derive(Eq, Debug)

///|
pub extend ConsoleCommand with Eq::{equal, not_equal}

///|
pub extend ConsoleCommand with @debug.Debug::{to_repr}

///|
/// Parse one console input line.
pub fn parse_console_line(line : String) -> ConsoleCommand {
  let trimmed = console_trim(line)
  if trimmed == "" {
    return Blank
  }
  if trimmed.has_prefix(".") {
    return match trimmed {
      ".help" => DotHelp
      ".tables" => DotTables
      ".quit" | ".exit" => DotQuit
      other => Invalid("unknown dot-command \{other} (try .help)")
    }
  }
  parse_table_call(trimmed)
}

///|
fn parse_table_call(trimmed : String) -> ConsoleCommand {
  let mut at = -1
  let mut i = 0
  for ch in trimmed {
    if ch == '.' {
      at = i
      break
    }
    i = i + 1
  }
  if at < 0 {
    return Invalid(
      "expected <table>.all() / .count() / .find(id) / .insert({...}) or .help",
    )
  }
  let table = trimmed[:at].to_owned()
  let mut first = ' '
  for ch in table {
    first = ch
    break
  }
  if table == "" || !(first >= 'A' && first <= 'Z') {
    return Invalid("table names start with an upper-case letter")
  }
  let rest = trimmed[at + 1:].to_owned()
  match rest {
    "all()" => TableAll(table)
    "count()" => TableCount(table)
    _ =>
      if rest.has_prefix("find(") && rest.has_suffix(")") {
        let inner = rest[5:rest.length() - 1].to_owned()
        match console_parse_int(inner) {
          Some(id) => TableFind(table, id)
          None => Invalid("find() takes an integer id")
        }
      } else if rest.has_prefix("insert(") && rest.has_suffix(")") {
        let inner = rest[7:rest.length() - 1].to_owned()
        match (@json.parse(inner) catch { _err => Json::null() }) {
          Object(fields) => TableInsert(table, Json::object(fields))
          _ => Invalid("insert() takes a JSON object")
        }
      } else {
        Invalid("unsupported call \{rest}")
      }
  }
}

///|
fn console_trim(line : String) -> String {
  let len = line.length()
  let mut start = 0
  let mut end = len
  while start < len {
    let ch = line[start]
    if ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' {
      start = start + 1
    } else {
      break
    }
  }
  while end > start {
    let ch = line[end - 1]
    if ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' {
      end = end - 1
    } else {
      break
    }
  }
  line[start:end].to_owned()
}

///|
fn console_parse_int(raw : String) -> Int? {
  if raw.length() == 0 {
    return None
  }
  let mut value = 0
  for ch in raw {
    if ch >= '0' && ch <= '9' {
      value = value * 10 + ch.to_int() - 48
    } else {
      return None
    }
  }
  Some(value)
}

///|
/// Execute a parsed command against the database and return the text to
/// print (empty string prints nothing). Never raises.
pub fn execute_console(
  db : @db.Database,
  cmd : ConsoleCommand,
  db_path : String,
) -> String {
  match cmd {
    Blank => ""
    DotHelp => console_help_text(db_path)
    DotTables => {
      let names = db.list_tables()
      if names.length() == 0 {
        "(no tables)"
      } else {
        let mut out = ""
        for name in names {
          out = out + name + "\n"
        }
        out
      }
    }
    DotQuit => ""
    Invalid(message) => "error: \{message}"
    TableAll(name) =>
      match db.table_schema(name) {
        None => "no table \{name}"
        Some(t) => {
          let rows = db.select_raw(t, "1=1", [], limit=200)
          let mut out = ""
          for row in rows {
            out = out + row.stringify() + "\n"
          }
          out + "(\{rows.length()} rows)"
        }
      }
    TableCount(name) =>
      match db.table_schema(name) {
        None => "no table \{name}"
        Some(t) => "\{db.count(t)}"
      }
    TableFind(name, id) =>
      match db.table_schema(name) {
        None => "no table \{name}"
        Some(t) =>
          match db.find_raw(t, id) {
            Some(row) => row.stringify()
            None => "not found"
          }
      }
    TableInsert(name, row) =>
      match db.table_schema(name) {
        None => "no table \{name}"
        Some(t) => {
          let fields : Map[String, Json] = Map([])
          match row {
            Object(map) =>
              for key, value in map {
                fields[key] = value
              }
            _ => ()
          }
          if db.insert_raw(t, fields) {
            "inserted, id = \{db.last_insert_rowid()}"
          } else {
            "insert failed"
          }
        }
      }
  }
}

///|
fn console_help_text(db_path : String) -> String {
  let lines = [
    "connected to sqlite://\{db_path}",
    "",
    "Table commands:",
    "  <Table>.all()               print up to 200 rows as JSON",
    "  <Table>.count()             print the row count",
    "  <Table>.find(<id>)          print one row by its primary key",
    "  <Table>.insert({...})       insert a JSON object",
    "",
    "Dot commands:",
    "  .tables                     list tables",
    "  .help                       show this help",
    "  .quit                       leave the console",
  ]
  join_lines(lines)
}

///|
/// Open `db_path` and run the interactive console loop on stdin/stdout.
/// Drives the async runtime for stdin reads, then closes the database.
pub fn run_console(db_path : String) -> Unit {
  let opened = @db.open(db_path)
  match opened {
    Some(db) => {
      @async.run_async_main(async fn() { console_loop(db, db_path) })
      db.close()
    }
    None => eprintln("moonway: cannot open database at \{db_path}")
  }
}

///|
async fn console_loop(db : @db.Database, db_path : String) -> Unit {
  println("moonway \{cli_version} · connected to sqlite://\{db_path}")
  println("Type .help for help, .quit to exit.")
  while true {
    @stdio.stdout.write("> ")
    let line = @stdio.stdin.read_until("\n")
    match line {
      None => {
        println("")
        break
      }
      Some(text) => {
        let out = execute_console(db, parse_console_line(text), db_path)
        if out != "" {
          println(out)
        }
      }
    }
  }
}
