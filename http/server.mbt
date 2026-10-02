///|
/// Serve HTTP/1.1 on 127.0.0.1:`port`, bridging the async runtime's server
/// to the synchronous `handler`. Blocks until the process is interrupted.
pub fn serve(port : Int, handler : (Request) -> Response) -> Unit {
  @async.run_async_main(async fn() {
    try {
      let addr = @async_socket.Addr::parse("127.0.0.1:\{port}")
      let server = @async_http.Server(addr)
      server.run_forever(async fn(request, body, conn) {
        let body_text = body.read_all().text() catch { _err => "" }
        let resp = handler(Request::from_runtime(request, body_text))
        conn.send_response(resp.status(), "OK")
        conn.write(resp.body())
        conn.end_response()
      })
    } catch {
      err =>
        eprintln("moonway: failed to start server on 127.0.0.1:\{port}: \{err}")
    }
  })
}
