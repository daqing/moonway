///|
test "model template renders fields, columns and promotion extends" {
  let src = model_src_t("Post", "posts", [
    ("title", "string"),
    ("published", "bool"),
  ])
  assert_true(src.contains("pub struct Post {"))
  assert_true(src.contains("  title : String"))
  assert_true(src.contains("  published : Bool"))
  assert_true(src.contains("derive(ToJson, FromJson)"))
  assert_true(src.contains("pub extend Post with ToJson::{to_json}"))
  assert_true(src.contains("pub extend Post with @json.FromJson::{from_json}"))
  assert_true(src.contains("\"posts\""))
  assert_true(src.contains("@db.column(\"title\", @db.TextT)"))
  assert_true(src.contains("@db.column(\"published\", @db.BoolT)"))
  assert_true(src.contains("@db.column(\"id\", @db.IntT, primary=true)"))
}

///|
test "handlers template pins generic row types" {
  let src = handlers_scaffold_t("Post", "posts")
  assert_true(
    src.contains("let items : Array[@models.Post] = db.all(@models.posts)"),
  )
  assert_true(src.contains("db.find(@models.posts, id)"))
  assert_true(
    src.contains("pub fn register_posts(app : @moonway.App, db : @db.Database)"),
  )
  assert_true(src.contains("ctx.status(400).text(\"invalid JSON body\")"))
  assert_true(src.contains("ctx.status(404).text(\"Not Found\")"))
}

///|
test "new templates pin native target, link flags and markers" {
  let mod_src = moon_mod_t("blog")
  assert_true(mod_src.contains("preferred_target = \"native\""))
  assert_true(mod_src.contains("name = \"blog\""))
  assert_true(mod_src.contains("daqing/moonway@"))
  let main_pkg = main_pkg_t("blog")
  assert_true(main_pkg.contains("-lsqlite3"))
  assert_true(main_pkg.contains("\"daqing/moonway\" @moonway"))
  assert_true(main_pkg.contains("blog/handlers"))
  assert_true(main_pkg.contains("blog/migrations"))
  let main_src = main_src_t()
  assert_true(main_src.contains("app.listen(3000)"))
  assert_true(main_src.contains("// moonway:register-handlers"))
  let models_src = models_src_t()
  assert_true(models_src.contains("// moonway:admin-tables"))
  let migrations_src = migrations_src_t()
  assert_true(migrations_src.contains("// moonway:migrations"))
}

///|
test "CLI version and generated dependency match the module version" {
  let manifest = @fs.read_file_to_string("moon.mod")
  assert_true(manifest.contains("version = \"\{dep_version()}\""))
  let mod_src = moon_mod_t("blog")
  assert_true(mod_src.contains("\"daqing/moonway@\{dep_version()}\","))
  assert_false(mod_src.contains("@v"))
}

///|
test "module name derives from path-like new arguments" {
  assert_eq(module_name("blog"), "blog")
  assert_eq(module_name("tmp/blog"), "blog")
  assert_eq(module_name("/tmp/m2"), "m2")
  assert_eq(module_name("/tmp/m2/"), "m2")
}

///|
test "new projects require the Preact frontend build" {
  let index = index_html_t("blog")
  assert_true(index.contains("<div id=\"app\"></div>"))
  assert_false(index.contains("<h1>"))
  assert_true(web_package_json_t().contains("--jsx-import-source=preact"))
  assert_true(gitignore_t().contains("static/app.js"))
  let readme = readme_t("blog")
  assert_true(readme.contains("npm install"))
  assert_true(readme.contains("npm run build"))
  assert_true(readme.contains("moon run cmd/blog"))
  assert_false(readme.contains("no build step"))
  assert_false(readme.contains("optional"))
}

///|
test "Preact template handles posts API errors and submissions" {
  let src = web_main_jsx_t("blog")
  assert_true(src.contains("from \"preact\""))
  assert_true(src.contains("from \"preact/hooks\""))
  assert_true(src.contains("if (!res.ok)"))
  assert_true(src.contains("method: \"POST\""))
  assert_true(src.contains("const id = posts.reduce("))
  assert_false(src.contains("Date.now()"))
  assert_true(src.contains("<form onSubmit={addPost}>"))
  assert_true(src.contains("await refreshPosts()"))
}

///|
test "version output carries the moonway prefix and never raises" {
  assert_true(version().has_prefix("moonway "))
}

///|
test "migration template references the models table" {
  let src = migration_scaffold_t("posts", 1)
  assert_true(src.contains("pub fn create_posts() -> @db.Migration {"))
  assert_true(
    src.contains(
      "@db.migration(1, \"create posts\", [@models.posts.create_sql()])",
    ),
  )
}

///|
test "to_lower_snake lower-cases the model name" {
  assert_eq(to_lower_snake("Post"), "post")
  assert_eq(to_lower_snake("BlogPost"), "blogpost")
}

///|
test "pad3 zero-pads migration versions" {
  assert_eq(pad3(1), "001")
  assert_eq(pad3(42), "042")
  assert_eq(pad3(123), "123")
}

///|
test "marker insertion places the line and reports missing markers" {
  let content = "fn all() {\n  [\n    // moonway:migrations\n  ]\n}"
  let inserted = insert_after_marker(
    content, "// moonway:migrations", "    create_posts(),",
  )
  match inserted {
    Some(text) => {
      assert_true(has_line(text, "    create_posts(),"))
      assert_true(has_line(text, "    // moonway:migrations"))
      assert_true(has_line(text, "  ]"))
    }
    None => fail("expected the marker to be found")
  }
  assert_true(insert_after_marker("no marker here", "// x", "y") is None)
}

///|
test "new project templates use app models and views directories" {
  let handlers_pkg = handlers_pkg_t("blog")
  assert_true(handlers_pkg.contains("\"blog/app/models\" @models"))
  let migrations_pkg = migrations_pkg_t("blog")
  assert_true(migrations_pkg.contains("\"blog/app/models\" @models"))
  let readme = readme_t("blog")
  assert_true(readme.contains("cd app/views"))
  assert_true(readme.contains("cd ../.."))
  assert_true(readme.contains("`app/views/src/main.jsx`"))
  let frontend_pkg = web_package_json_t()
  assert_true(frontend_pkg.contains("--outfile=../../static/app.js"))
}
