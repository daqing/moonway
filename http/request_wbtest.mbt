///|
test "from_runtime maps every runtime method to an upper-case verb" {
  let cases = [
    (@async_http.Get, "GET"),
    (@async_http.Head, "HEAD"),
    (@async_http.Post, "POST"),
    (@async_http.Put, "PUT"),
    (@async_http.Delete, "DELETE"),
    (@async_http.Connect, "CONNECT"),
    (@async_http.Options, "OPTIONS"),
    (@async_http.Trace, "TRACE"),
    (@async_http.Patch, "PATCH"),
  ]
  for case in cases {
    let (meth, expected) = case
    let runtime : @async_http.Request = { meth, path: "/", headers: Map([]), }
    assert_eq(Request::from_runtime(runtime, "").verb, expected)
  }
}

///|
test "from_runtime copies headers and keeps path and body" {
  let headers = Map([
    (@async_http.CaseInsensitiveString("X-Test"), "1"),
    (@async_http.CaseInsensitiveString("Content-Type"), "text/plain"),
  ])
  let runtime : @async_http.Request = {
    meth: @async_http.Get,
    path: "/hi",
    headers,
  }
  let req = Request::from_runtime(runtime, "hello")
  assert_eq(req.path, "/hi")
  assert_eq(req.body, "hello")
  assert_eq(req.headers.length(), 2)
  assert_eq(req.header("X-Test"), Some("1"))
  assert_eq(req.header("Content-Type"), Some("text/plain"))
}
