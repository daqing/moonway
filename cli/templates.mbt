///|
fn model_src_t(
  model : String,
  plural : String,
  fields : Array[(String, String)],
) -> String {
  let lines = ["///|", "pub struct \{model} {", "  id : Int"]
  for pair in fields {
    let name = pair.0
    let token = pair.1
    let t = field_moonbit_type(token).unwrap_or("String")
    lines.push("  \{name} : \{t}")
  }
  lines.push("} derive(ToJson, FromJson)")
  lines.push("")
  lines.push("///|")
  lines.push("pub extend \{model} with ToJson::{to_json}")
  lines.push("")
  lines.push("///|")
  lines.push("pub extend \{model} with @json.FromJson::{from_json}")
  lines.push("")
  lines.push("///|")
  lines.push("pub let \{plural} : @db.Table = @db.table(")
  lines.push("  \"\{plural}\",")
  lines.push("  [")
  lines.push("    @db.column(\"id\", @db.IntT, primary=true),")
  for pair in fields {
    let name = pair.0
    let token = pair.1
    let t = field_column_type(token).unwrap_or("TextT")
    lines.push("    @db.column(\"\{name}\", @db.\{t}),")
  }
  lines.push("  ],")
  lines.push(")")
  join_lines(lines)
}

///|
fn handlers_scaffold_t(model : String, plural : String) -> String {
  let snake = to_lower_snake(model)
  join_lines([
    "///|",
    "fn parse_\{snake}(body : String) -> @models.\{model}? {",
    "  try {",
    "    Some(@json.from_json(@json.parse(body)))",
    "  } catch {",
    "    _err => None",
    "  }",
    "}",
    "",
    "///|",
    "fn parse_id(raw : String) -> Int? {",
    "  match (@json.parse(raw) catch { _err => Json::null() }) {",
    "    Number(n, ..) => Some(n.to_int())",
    "    _ => None",
    "  }",
    "}",
    "",
    "///|",
    "/// Register the \{plural} routes on the app.",
    "pub fn register_\{plural}(app : @moonway.App, db : @db.Database) -> Unit {",
    "  app.get(\"/\{plural}\", ctx => {",
    "    let items : Array[@models.\{model}] = db.all(@models.\{plural})",
    "    ctx.json(items)",
    "  })",
    "  app.post(\"/\{plural}\", ctx => {",
    "    match parse_\{snake}(ctx.body()) {",
    "      Some(post) =>",
    "        if db.insert(@models.\{plural}, post) {",
    "          ctx.status(201).json(post)",
    "        } else {",
    "          ctx.status(500).text(\"insert failed\")",
    "        }",
    "      None => ctx.status(400).text(\"invalid JSON body\")",
    "    }",
    "  })",
    "  app.get(\"/\{plural}/:id\", ctx => {",
    "    let id = match ctx.param(\"id\") {",
    "      Some(raw) => parse_id(raw)",
    "      None => None",
    "    }",
    "    let found : @models.\{model}? = match id {",
    "      Some(id) => db.find(@models.\{plural}, id)",
    "      None => None",
    "    }",
    "    match found {",
    "      Some(post) => ctx.json(post)",
    "      None => ctx.status(404).text(\"Not Found\")",
    "    }",
    "  })",
    "}",
  ])
}

///|
fn migration_scaffold_t(plural : String, version : Int) -> String {
  join_lines([
    "///|",
    "pub fn create_\{plural}() -> @db.Migration {",
    "  @db.migration(\{version}, \"create \{plural}\", [@models.\{plural}.create_sql()])",
    "}",
  ])
}
