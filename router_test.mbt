///|
fn param_or(ctx : @moonway.Context, name : String, fallback : String) -> String {
  match ctx.param(name) {
    Some(value) => value
    None => fallback
  }
}

///|
test "path parameter is captured into ctx.param" {
  let app = @moonway.new()
  app.get("/posts/:id", ctx => ctx.text("post:\{param_or(ctx, "id", "?")}"))
  let resp = app.handle("GET", "/posts/42")
  assert_eq(resp.status(), 200)
  assert_eq(resp.body(), "post:42")
}

///|
test "static segments beat :param captures" {
  let app = @moonway.new()
  app.get("/users/:id", ctx => ctx.text("user:\{param_or(ctx, "id", "?")}"))
  app.get("/users/me", ctx => ctx.text("current user"))
  assert_eq(app.handle("GET", "/users/me").body(), "current user")
  assert_eq(app.handle("GET", "/users/7").body(), "user:7")
}

///|
test "two parameters in one pattern" {
  let app = @moonway.new()
  app.get("/files/:dir/:name", ctx => {
    ctx.text("\{param_or(ctx, "dir", "?")}/\{param_or(ctx, "name", "?")}")
  })
  assert_eq(app.handle("GET", "/files/docs/a.txt").body(), "docs/a.txt")
}

///|
test "query strings are ignored when routing" {
  let app = @moonway.new()
  app.get("/posts/:id", ctx => ctx.text("post:\{param_or(ctx, "id", "?")}"))
  let resp = app.handle("GET", "/posts/9?sort=asc")
  assert_eq(resp.status(), 200)
  assert_eq(resp.body(), "post:9")
}

///|
test "differing segment counts never match" {
  let app = @moonway.new()
  app.get("/posts/:id", ctx => ctx.text("one"))
  assert_eq(app.handle("GET", "/posts").status(), 404)
  assert_eq(app.handle("GET", "/posts/1/replies").status(), 404)
}

///|
test "known path with wrong verb returns 405 and Allow" {
  let app = @moonway.new()
  app.get("/posts/:id", ctx => ctx.text("one"))
  app.post("/posts/:id", ctx => ctx.text("two"))
  app.delete("/posts/:id", ctx => ctx.text("three"))
  let resp = app.handle("PUT", "/posts/42")
  assert_eq(resp.status(), 405)
  assert_eq(resp.header("Allow"), Some("GET, POST, DELETE"))
  assert_eq(resp.body(), "Method Not Allowed")
}

///|
test "unknown path still returns plain 404" {
  let app = @moonway.new()
  app.get("/posts/:id", ctx => ctx.text("one"))
  let resp = app.handle("GET", "/comments/1")
  assert_eq(resp.status(), 404)
  assert_eq(resp.body(), "Not Found")
}

///|
test "405 considers parameter shapes, not literal paths" {
  let app = @moonway.new()
  app.get("/users/:id", ctx => ctx.text("one"))
  let resp = app.handle("POST", "/users/9")
  assert_eq(resp.status(), 405)
  assert_eq(resp.header("Allow"), Some("GET"))
}
