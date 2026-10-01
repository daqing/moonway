///|
test "GET on a registered path returns the handler response" {
  let app = @moonway.new()
  app.get("/", ctx => ctx.text("Hello, moonway!"))
  let resp = app.handle("GET", "/")
  assert_eq(resp.status(), 200)
  assert_eq(resp.body(), "Hello, moonway!")
  assert_eq(resp.header("Content-Type"), Some("text/plain; charset=utf-8"))
}

///|
test "registered verbs dispatch to their own handlers" {
  let app = @moonway.new()
  app.post("/echo", ctx => ctx.text(ctx.verb()))
  let resp = app.handle("POST", "/echo")
  assert_eq(resp.status(), 200)
  assert_eq(resp.body(), "POST")
}

///|
test "unknown path returns 404 with a body" {
  let app = @moonway.new()
  app.get("/", ctx => ctx.text("Hello, moonway!"))
  let resp = app.handle("GET", "/missing")
  assert_eq(resp.status(), 404)
  assert_eq(resp.body(), "Not Found")
}

///|
test "middlewares run in registration order before the handler" {
  let app = @moonway.new()
  app.use(ctx => ctx.header("X-Order", "first"))
  app.use(ctx => ctx.header("X-Order", "second"))
  app.get("/", ctx => ctx.text("ok"))
  let resp = app.handle("GET", "/")
  assert_eq(resp.header("X-Order"), Some("second"))
}
