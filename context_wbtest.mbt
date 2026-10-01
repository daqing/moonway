///|
test "param accessor reads the params map" {
  let ctx = Context::new(@http.Request::new("GET", "/posts/42"))
  ctx.params["id"] = "42"
  assert_eq(ctx.param("id"), Some("42"))
  assert_eq(ctx.param("missing"), None)
}

///|
test "a fresh context defaults to status 200 and empty params" {
  let ctx = Context::new(@http.Request::new("GET", "/"))
  assert_eq(ctx.response.status(), 200)
  assert_eq(ctx.param("id"), None)
}
