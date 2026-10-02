///|
test "path parameter is captured into ctx.param" {
  let app = @moonway.new()
  app.get("/posts/:id", ctx => ctx.text("post \{ctx.param("id")}"))
  let resp = app.handle("GET", "/posts/42")
  assert_eq(resp.status(), 200)
  assert_eq(resp.body(), "post Some(42)")
}

///|
test "static segments beat :param captures" {
  let app = @moonway.new()
  app.get("/users/:id", ctx => ctx.text("user \{ctx.param("id")}"))
  app.get("/users/me", ctx => ctx.text("current user"))
  assert_eq(app.handle("GET", "/users/me").body(), "current user")
  assert_eq(app.handle("GET", "/users/7").body(), "user Some(7)")
}

///|
test "two parameters in one pattern" {
  let app = @moonway.new()
  app.get("/files/:dir/:name", ctx => {
    ctx.text("\{ctx.param("dir")}/\{ctx.param("name")}")
  })
  assert_eq(
    app.handle("GET", "/files/docs/a.txt").body(),
    "Some(docs)/Some(a.txt)",
  )
}

///|
test "query strings are ignored when routing" {
  let app = @moonway.new()
  app.get("/posts/:id", ctx => ctx.text("post \{ctx.param("id")}"))
  let resp = app.handle("GET", "/posts/9?sort=asc")
  assert_eq(resp.status(), 200)
  assert_eq(resp.body(), "post Some(9)")
}

///|
test "differing segment counts never match" {
  let app = @moonway.new()
  app.get("/posts/:id", ctx => ctx.text("one"))
  assert_eq(app.handle("GET", "/posts").status(), 404)
  assert_eq(app.handle("GET", "/posts/1/replies").status(), 404)
}
