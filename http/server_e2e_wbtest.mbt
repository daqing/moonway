///|
async test "end-to-end: real server answers a real HTTP client" {
  let port = 18091
  @async.with_task_group(async fn(group) {
    group.spawn_bg(
      async fn() {
        serve_async(port, req => {
          let resp = Response::new()
          if req.path == "/hi" {
            resp.set_body("hello from moonway")
          } else {
            resp.set_status(404)
            resp.set_body("Not Found")
          }
          resp
        }) catch {
          err => eprintln("moonway: test server failed: \{err}")
        }
      },
      no_wait=true,
    )
    let (resp, data) = @async_http.get("http://127.0.0.1:\{port}/hi")
    assert_eq(resp.code, 200)
    assert_eq(data.text(), "hello from moonway")
    let (nf, body) = @async_http.get("http://127.0.0.1:\{port}/missing")
    assert_eq(nf.code, 404)
    assert_eq(body.text(), "Not Found")
  })
}
