///|
/// Handle `moonway generate scaffold <Model> [field:type ...]` in the
/// current project: writes the model, handlers and migration files, then
/// updates the registries (admin tables, migrations, handler registration)
/// through their markers.
fn execute_scaffold(model : String, field_tokens : Array[String]) -> Unit {
  let mut first = ' '
  for ch in model {
    first = ch
    break
  }
  if model.length() == 0 || !(first >= 'A' && first <= 'Z') {
    eprintln(
      "moonway: model names must start with an upper-case letter (got \{model})",
    )
    return
  }
  let fields : Array[(String, String)] = []
  for token in field_tokens {
    match parse_field(token) {
      Some(pair) => fields.push(pair)
      None => {
        eprintln(
          "moonway: invalid field \{token} (expected name:type with type string|text|int|bool|float)",
        )
        return
      }
    }
  }
  let snake = to_lower_snake(model)
  let plural = snake + "s"
  if @fs.path_exists("models/\{snake}.mbt") {
    eprintln("moonway: models/\{snake}.mbt already exists")
    return
  }
  let version = next_migration_version()
  let version_name = pad3(version)
  try {
    @fs.write_string_to_file(
      "models/\{snake}.mbt",
      model_src_t(model, plural, fields),
    )
    @fs.write_string_to_file(
      "handlers/\{plural}.mbt",
      handlers_scaffold_t(model, plural),
    )
    @fs.write_string_to_file(
      "migrations/\{version_name}_create_\{plural}.mbt",
      migration_scaffold_t(plural, version),
    )
  } catch {
    err => {
      eprintln(
        "moonway: failed to write scaffold files: \{@debug.Debug::to_repr(err)}",
      )
      return
    }
  }
  update_registry(
    "models/models.mbt",
    "// moonway:admin-tables",
    "    \{plural},",
  )
  update_registry(
    "migrations/migrations.mbt",
    "// moonway:migrations",
    "    create_\{plural}(),",
  )
  update_registry(
    "cmd/main/main.mbt",
    "// moonway:register-handlers",
    "  @handlers.register_\{plural}(app, db)",
  )
  println("created  models/\{snake}.mbt")
  println("created  handlers/\{plural}.mbt")
  println("created  migrations/\{version_name}_create_\{plural}.mbt")
  println(
    "updated  models/models.mbt, migrations/migrations.mbt, cmd/main/main.mbt",
  )
}

///|
/// "name:type" -> (name, type token), or None when malformed.
pub fn parse_field(token : String) -> (String, String)? {
  let parts : Array[String] = []
  for part in token.split(":") {
    parts.push(part.to_owned())
  }
  if parts.length() != 2 || parts[0] == "" || parts[1] == "" {
    return None
  }
  Some((parts[0], parts[1]))
}

///|
/// MoonBit struct field type for a scaffold type token.
pub fn field_moonbit_type(token : String) -> String? {
  match token {
    "string" | "text" => Some("String")
    "int" => Some("Int")
    "bool" => Some("Bool")
    "float" => Some("Double")
    _ => None
  }
}

///|
/// @db.ColumnType constructor for a scaffold type token.
pub fn field_column_type(token : String) -> String? {
  match token {
    "string" | "text" => Some("TextT")
    "int" => Some("IntT")
    "bool" => Some("BoolT")
    "float" => Some("RealT")
    _ => None
  }
}

///|
fn to_lower_snake(model : String) -> String {
  let mut out = ""
  for ch in model {
    if ch >= 'A' && ch <= 'Z' {
      out = out + ch.to_string().to_lower()
    } else {
      out = out + ch.to_string()
    }
  }
  out
}

///|
fn next_migration_version() -> Int {
  let mut count = 0
  let listed = @fs.read_dir("migrations") catch { _err => [] }
  for entry in listed {
    if entry.has_prefix("0") && entry.has_suffix(".mbt") {
      count = count + 1
    }
  }
  count + 1
}

///|
fn pad3(n : Int) -> String {
  if n < 10 {
    "00\{n}"
  } else if n < 100 {
    "0\{n}"
  } else {
    "\{n}"
  }
}

///|
/// Insert `line` after `marker` in the file, unless the line is already
/// present. Missing files or markers are reported but not fatal.
fn update_registry(path : String, marker : String, line : String) -> Unit {
  let content = @fs.read_file_to_string(path) catch {
    _err => {
      eprintln("moonway: warning: could not update \{path} (missing?)")
      return
    }
  }
  if has_line(content, line) {
    return
  }
  match insert_after_marker(content, marker, line) {
    Some(updated) =>
      @fs.write_string_to_file(path, updated) catch {
        err =>
          eprintln(
            "moonway: warning: could not rewrite \{path}: \{@debug.Debug::to_repr(err)}",
          )
      }
    None => {
      let already = has_line(content, line)
      if !already {
        eprintln("moonway: warning: marker \{marker} not found in \{path}")
      }
    }
  }
}

///|
fn has_line(content : String, line : String) -> Bool {
  for l in content.split("\n") {
    if l.to_owned() == line {
      return true
    }
  }
  false
}

///|
/// Insert a line after the marker line; None when the marker is missing.
fn insert_after_marker(
  content : String,
  marker : String,
  line : String,
) -> String? {
  let lines : Array[String] = []
  for l in content.split("\n") {
    lines.push(l.to_owned())
  }
  let mut at = -1
  for i, l in lines {
    if l.contains(marker) {
      at = i
    }
  }
  if at < 0 {
    return None
  }
  let updated = []
  for i, l in lines {
    updated.push(l)
    if i == at {
      updated.push(line)
    }
  }
  Some(join_lines(updated))
}
