///|
fn ensure_dir(path : String) -> Unit raise {
  if @fs.path_exists(path) {
    return
  }
  // create_dir is not recursive: build the path one component at a time
  let mut built = ""
  for part in path.split("/") {
    built = built + part.to_owned()
    if built != "" && !@fs.path_exists(built) {
      @fs.create_dir(built)
    }
    built = built + "/"
  }
}

///|
/// Derive the module name from a possibly path-like `new` argument:
/// `moonway new blog` -> "blog", `moonway new /tmp/m2` -> "m2".
fn module_name(path : String) -> String {
  let mut name = path
  for part in path.split("/") {
    if part.length() > 0 {
      name = part.to_owned()
    }
  }
  name
}

///|
/// Handle `moonway new <name> [--dir <dir>]`: scaffold an application in
/// `<dir>/<name>` (default dir is the working directory). `<name>` may be a
/// path, in which case the module name is the last path component.
fn execute_new(name : String, dir : String) -> Unit {
  let root = if dir == "." { name } else { dir + "/" + name }
  let mod_name = module_name(root)
  if @fs.path_exists(root) {
    eprintln("moonway: \{root} already exists")
    return
  }
  try {
    ensure_dir(dir)
    ensure_dir(root)
    ensure_dir(root + "/cmd")
    ensure_dir(root + "/cmd/\{mod_name}")
    ensure_dir(root + "/app/models")
    ensure_dir(root + "/handlers")
    ensure_dir(root + "/migrations")
    ensure_dir(root + "/app/frontend/src")
    ensure_dir(root + "/app/templates")
    ensure_dir(root + "/static")
    ensure_dir(root + "/data")
    @fs.write_string_to_file(root + "/moon.mod", moon_mod_t(mod_name))
    @fs.write_string_to_file(root + "/.gitignore", gitignore_t())
    @fs.write_string_to_file(root + "/Procfile", procfile_t(mod_name))
    @fs.write_string_to_file(root + "/README.mbt.md", readme_t(mod_name))
    @fs.write_string_to_file(
      root + "/cmd/\{mod_name}/moon.pkg",
      main_pkg_t(mod_name),
    )
    @fs.write_string_to_file(
      root + "/cmd/\{mod_name}/main.mbt",
      main_src_t(mod_name),
    )
    @fs.write_string_to_file(root + "/app/models/moon.pkg", models_pkg_t())
    @fs.write_string_to_file(root + "/app/models/models.mbt", models_src_t())
    @fs.write_string_to_file(
      root + "/handlers/moon.pkg",
      handlers_pkg_t(mod_name),
    )
    @fs.write_string_to_file(root + "/handlers/handlers.mbt", handlers_src_t())
    @fs.write_string_to_file(
      root + "/migrations/moon.pkg",
      migrations_pkg_t(mod_name),
    )
    @fs.write_string_to_file(
      root + "/migrations/migrations.mbt",
      migrations_src_t(),
    )
    @fs.write_string_to_file(
      root + "/app/templates/moon.pkg",
      templates_pkg_t(),
    )
    @fs.write_string_to_file(root + "/app/templates/home.templ", home_templ_t())
    @fs.write_string_to_file(
      root + "/app/templates/home_templ.mbt",
      home_templ_generated_t(),
    )
    @fs.write_string_to_file(root + "/app/templates/pages.mbt", pages_src_t())
    @fs.write_string_to_file(
      root + "/app/frontend/package.json",
      web_package_json_t(),
    )
    @fs.write_string_to_file(
      root + "/app/frontend/src/main.jsx",
      web_main_jsx_t(),
    )
    println("Created \{root}")
    println("Next steps:")
    println("  cd \{root}")
    println("  moon update")
    println("Start all development processes with Foreman:")
    println("  foreman start")
    println("Or build the frontend and start only the server:")
    println("  cd app/frontend && npm install && npm run build && cd ../..")
    println("  moon run cmd/\{mod_name}")
  } catch {
    err =>
      eprintln(
        "moonway: failed to create \{root}: \{@debug.Debug::to_repr(err)}",
      )
  }
}

///|
/// Version pinned into generated `moon.mod` imports. moon.mod dependency
/// versions are bare semver, so strip the leading "v" used in display
/// strings — `"pkg@v0.11.8"` fails to parse with `SourceDependencyInfo`.
fn dep_version() -> String {
  let v = cli_version()
  if v.has_prefix("v") {
    v[1:].to_owned()
  } else {
    v
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
    "  \"daqing/moonway@\{dep_version()}\",",
    "  \"daqing/moon-templ@0.1.0\",",
    "  \"moonbitlang/async@0.22.4\",",
    "}",
  ])
}

///|
fn gitignore_t() -> String {
  join_lines([
    "_build/", "target/", ".mooncakes/", "node_modules/", "*.db", "static/app.js",
  ])
}

///|
fn procfile_t(name : String) -> String {
  join_lines([
    "web: watchexec --restart --exts mbt --project-origin . -- moon run cmd/\{name}",
    "templ: moon-templ generate --watch app/templates/...",
    "frontend: cd app/frontend && npm install && npm run dev",
  ])
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
    "Build the Preact islands to start only the server:",
    "",
    "```",
    "moon update",
    "cd app/frontend",
    "npm install",
    "npm run build",
    "cd ../..",
    "moon run cmd/\{name}",
    "```",
    "",
    "Then open <http://localhost:3000>.",
    "",
    "The SQLite database is stored at `data/app.db`; `moonway new` creates the `data/` directory.",
    "",
    "On macOS, install `watchexec` with Homebrew:",
    "",
    "```",
    "brew install watchexec",
    "```",
    "",
    "On Linux, install it with Cargo:",
    "",
    "```",
    "cargo install watchexec-cli --locked",
    "watchexec --version",
    "```",
    "",
    "Make sure `~/.cargo/bin` is on your `PATH`. Some distributions also provide a package:",
    "",
    "```",
    "# Debian / Ubuntu (when available in the distribution repositories)",
    "sudo apt install watchexec",
    "",
    "# Fedora",
    "sudo dnf install watchexec",
    "",
    "# Arch Linux",
    "sudo pacman -S watchexec",
    "```",
    "",
    "If your distribution does not provide the package, use Cargo or download a prebuilt Linux binary from [watchexec releases](https://github.com/watchexec/watchexec/releases).",
    "",
    "For development, the included `Procfile` runs the web server, templ watcher, and frontend watcher together. With `moon-templ`, [watchexec](https://github.com/watchexec/watchexec), Node.js, npm, and [Foreman](https://github.com/ddollar/foreman) on your PATH:",
    "",
    "```",
    "foreman start",
    "```",
    "",
    "The templ watcher regenerates templates whenever `.templ` files change.",
    "The web process watches `.mbt` files, recompiles and restarts the server after generated code changes; refresh the browser to see template updates.",
    "The frontend process installs npm dependencies and rebuilds `static/app.js` on changes, so no manual `npm run build` is needed.",
    "",
    "## Templates and Preact islands",
    "",
    "`app/templates/home.templ` defines `/` with [moon-templ](https://mooncakes.io/docs/daqing/moon-templ@0.1.0) and `data-island` mount points.",
    "`app/frontend/src/main.jsx` hydrates the Counter button on the same page.",
    "The generated `home_templ.mbt` is included, so the initial build needs no template CLI.",
    "After editing the template, regenerate it with the `moon-templ` CLI on your PATH:",
    "",
    "```",
    "moon-templ generate app/templates/home.templ",
    "```",
    "",
    "The frontend build writes `static/app.js`. Without it, the server-rendered HTML still works, but the islands are not interactive.",
    "",
    "## Scaffold a model",
    "",
    "```",
    "moonway generate scaffold Post title:string body:text published:bool",
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
    "  \"\{name}/app/templates\" @templates,",
    "  \"moonbitlang/async\" @async,",
    "  \"moonbitlang/async/stdio\" @stdio,",
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
    "  let db = @moonway.sqlite(\"data/app.db\")",
    "  if !db.migrate(@migrations.all()) {",
    "    abort(\"moonway: migrations failed\")",
    "  }",
    "  @handlers.register(app, db)",
    "  // moonway:register-handlers",
    "  app.get(\"/\", ctx => ctx.html(@templates.home_page(\"\{name}\")))",
    "  app.static_files(\"static\")",
    "  @async.run_async_main(async fn() {",
    "    @stdio.stdout.write(\"app is listening at http://127.0.0.1:3000\\n\")",
    "  })",
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
    "  \"\{name}/app/models\" @models,",
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
    "  \"\{name}/app/models\" @models,",
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
