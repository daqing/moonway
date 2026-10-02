///|
fn ensure_dir(path : String) -> Unit raise {
  if !@fs.path_exists(path) {
    @fs.create_dir(path)
  }
}

///|
/// Handle `moonway new <name> [--dir <dir>]`: scaffold an application in
/// `<dir>/<name>` (default dir is the working directory).
fn execute_new(name : String, dir : String) -> Unit {
  let root = if dir == "." { name } else { dir + "/" + name }
  if @fs.path_exists(root) {
    eprintln("moonway: \{root} already exists")
    return
  }
  try {
    ensure_dir(dir)
    ensure_dir(root)
    ensure_dir(root + "/cmd")
    ensure_dir(root + "/cmd/main")
    ensure_dir(root + "/models")
    ensure_dir(root + "/handlers")
    ensure_dir(root + "/migrations")
    ensure_dir(root + "/web")
    @fs.write_string_to_file(root + "/moon.mod", moon_mod_t(name))
    @fs.write_string_to_file(root + "/.gitignore", gitignore_t())
    @fs.write_string_to_file(root + "/README.mbt.md", readme_t(name))
    @fs.write_string_to_file(root + "/cmd/main/moon.pkg", main_pkg_t(name))
    @fs.write_string_to_file(root + "/cmd/main/main.mbt", main_src_t(name))
    @fs.write_string_to_file(root + "/models/moon.pkg", models_pkg_t())
    @fs.write_string_to_file(root + "/models/models.mbt", models_src_t())
    @fs.write_string_to_file(root + "/handlers/moon.pkg", handlers_pkg_t(name))
    @fs.write_string_to_file(root + "/handlers/handlers.mbt", handlers_src_t())
    @fs.write_string_to_file(
      root + "/migrations/moon.pkg",
      migrations_pkg_t(name),
    )
    @fs.write_string_to_file(
      root + "/migrations/migrations.mbt",
      migrations_src_t(),
    )
    @fs.write_string_to_file(root + "/web/moon.pkg", "")
    println("Created \{root}")
    println("Next steps:")
    println("  cd \{root}")
    println("  moon update")
    println("  moon run cmd/main")
  } catch {
    err =>
      eprintln(
        "moonway: failed to create \{root}: \{@debug.Debug::to_repr(err)}",
      )
  }
}

///|
fn moon_mod_t(name : String) -> String {
  join_lines([
    "name = \"\{name}\"",
    "",
    "version = \"0.1.0\"",
    "",
    "readme = \"README.mbt.md\"",
    "",
    "repository = \"\"",
    "",
    "license = \"MIT\"",
    "",
    "keywords = []",
    "",
    "preferred_target = \"native\"",
    "",
    "description = \"A moonway app\"",
    "",
    "import {",
    "  \"daqing/moonway@\{cli_version}\",",
    "}",
  ])
}

///|
fn gitignore_t() -> String {
  join_lines(["_build/", "target/", ".mooncakes/", "*.db"])
}

///|
fn readme_t(name : String) -> String {
  join_lines([
    "# \{name}",
    "",
    "A [moonway](https://github.com/daqing/moonway) app.",
    "",
    "## Run",
    "",
    "```",
    "moon run cmd/main",
    "```",
    "",
    "Then open <http://localhost:3000>.",
    "",
    "## Scaffold a model",
    "",
    "```",
    "moonway generate scaffold Post title:string body:text",
    "```",
  ])
}

///|
fn main_pkg_t(name : String) -> String {
  join_lines([
    "import {",
    "  \"daqing/moonway\" @moonway,",
    "  \"\{name}/handlers\" @handlers,",
    "  \"\{name}/migrations\" @migrations,",
    "}",
    "",
    "supported_targets = \"native\"",
    "",
    "pkgtype(kind: \"executable\")",
    "",
    "options(",
    "  link: { \"native\": { \"cc-link-flags\": \"-lsqlite3\" } },",
    ")",
  ])
}

///|
fn main_src_t(name : String) -> String {
  join_lines([
    "///|",
    "fn main {",
    "  let app = @moonway.new()",
    "  let db = @moonway.sqlite(\"app.db\")",
    "  if !db.migrate(@migrations.all()) {",
    "    abort(\"moonway: migrations failed\")",
    "  }",
    "  @handlers.register(app, db)",
    "  // moonway:register-handlers",
    "  app.get(\"/\", ctx => ctx.text(\"Welcome to \{name}\"))",
    "  app.listen(3000)",
    "}",
  ])
}

///|
fn models_pkg_t() -> String {
  join_lines([
    "import {", "  \"daqing/moonway/db\" @db,", "  \"moonbitlang/core/json\" @json,",
    "}", "", "supported_targets = \"native\"", "", "options(", "  link: { \"native\": { \"cc-link-flags\": \"-lsqlite3\" } },",
    ")",
  ])
}

///|
fn models_src_t() -> String {
  join_lines([
    "///|", "/// Tables for the admin UI. moonway generate scaffold appends entries here.",
    "pub fn admin_tables() -> Array[@db.Table] {", "  [", "    // moonway:admin-tables",
    "  ]", "}",
  ])
}

///|
fn handlers_pkg_t(name : String) -> String {
  join_lines([
    "import {",
    "  \"daqing/moonway\" @moonway,",
    "  \"daqing/moonway/db\" @db,",
    "  \"\{name}/models\" @models,",
    "  \"moonbitlang/core/json\" @json,",
    "}",
    "",
    "supported_targets = \"native\"",
    "",
    "options(",
    "  link: { \"native\": { \"cc-link-flags\": \"-lsqlite3\" } },",
    ")",
  ])
}

///|
fn handlers_src_t() -> String {
  join_lines([
    "///|", "/// Register all scaffolded routes on the app.", "pub fn register(_app : @moonway.App, _db : @db.Database) -> Unit {}",
  ])
}

///|
fn migrations_pkg_t(name : String) -> String {
  join_lines([
    "import {",
    "  \"daqing/moonway/db\" @db,",
    "  \"\{name}/models\" @models,",
    "}",
    "",
    "supported_targets = \"native\"",
    "",
    "options(",
    "  link: { \"native\": { \"cc-link-flags\": \"-lsqlite3\" } },",
    ")",
  ])
}

///|
fn migrations_src_t() -> String {
  join_lines([
    "///|", "/// All migrations, in ascending version order.", "pub fn all() -> Array[@db.Migration] {",
    "  [", "    // moonway:migrations", "  ]", "}",
  ])
}
