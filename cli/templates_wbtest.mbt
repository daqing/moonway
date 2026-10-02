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
  let main_src = main_src_t("blog")
  assert_true(main_src.contains("app.listen(3000)"))
  assert_true(main_src.contains("// moonway:register-handlers"))
  let models_src = models_src_t()
  assert_true(models_src.contains("// moonway:admin-tables"))
  let migrations_src = migrations_src_t()
  assert_true(migrations_src.contains("// moonway:migrations"))
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
