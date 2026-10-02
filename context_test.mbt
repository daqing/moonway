///|
struct Point {
  x : Int
  y : Int
} derive(ToJson)

///|
test "status and json builders chain" {
  let app = @moonway.new()
  app.post("/points", ctx => ctx.status(201).json(Point::{ x: 1, y: 2, }))
  let resp = app.handle("POST", "/points")
  assert_eq(resp.status(), 201)
  assert_eq(resp.header("Content-Type"), Some("application/json"))
  assert_eq(resp.body(), "{\"x\":1,\"y\":2}")
}

///|
test "handler can read the request body" {
  let app = @moonway.new()
  app.post("/echo", ctx => ctx.text(ctx.body()))
  let resp = app.handle("POST", "/echo", body="ping")
  assert_eq(resp.body(), "ping")
}

///|
test "handler can read the request line" {
  let app = @moonway.new()
  app.delete("/who", ctx => ctx.text("\{ctx.verb()} \{ctx.path()}"))
  let resp = app.handle("DELETE", "/who")
  assert_eq(resp.body(), "DELETE /who")
}

///|
test "html builder sets the html content type" {
  let app = @moonway.new()
  app.get("/", ctx => ctx.html("<h1>Hi</h1>"))
  let resp = app.handle("GET", "/")
  assert_eq(resp.header("Content-Type"), Some("text/html; charset=utf-8"))
}
