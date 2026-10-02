///|
test "static files serve with content types, index fallback and traversal guard" {
  let dir = "_build/static-test"
  let _ = @fs.create_dir(dir) catch { _err => () }
  @fs.write_string_to_file(dir + "/index.html", "<h1>home</h1>")
  @fs.write_string_to_file(dir + "/app.js", "console.log(1)")
  @fs.write_string_to_file(dir + "/logo.svg", "<svg/>")
  @fs.write_string_to_file("_build/outsider.txt", "secret")
  let app = new()
  app.get("/api", ctx => ctx.text("dynamic"))
  app.static_files(dir)
  let home = app.handle("GET", "/")
  assert_eq(home.status(), 200)
  assert_true(home.body().contains("home"))
  let js = app.handle("GET", "/app.js")
  let ct = match js.header("Content-Type") {
    Some(v) => v
    None => "None"
  }
  assert_eq(ct, "text/javascript; charset=utf-8")
  assert_eq(js.body(), "console.log(1)")
  let svg = app.handle("GET", "/logo.svg")
  assert_eq(svg.header("Content-Type"), Some("image/svg+xml"))
  let dynamic = app.handle("GET", "/api")
  assert_eq(dynamic.body(), "dynamic")
  assert_eq(app.handle("GET", "/missing.js").status(), 404)
  assert_eq(app.handle("GET", "/../outsider.txt").status(), 404)
  assert_eq(app.handle("GET", "/../../../etc/passwd").status(), 404)
}
