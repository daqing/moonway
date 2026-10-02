///|
/// Core serving loop. Must run inside the async runtime (an async fn main,
/// or a task spawned within one). Binds 127.0.0.1:`port`; raises on bind
/// failure.
pub async fn serve_async(port : Int, handler : (Request) -> Response) -> Unit {
  let addr = @async_socket.Addr::parse("127.0.0.1:\{port}")
  let server = @async_http.Server(addr, reuse_addr=true)
  server.run_forever(
    async fn(request, body, conn) {
      let body_text = body.read_all().text() catch { _err => "" }
      let resp = handler(Request::from_runtime(request, body_text))
      resp.write_to(conn)
    },
    allow_failure=true,
  )
}

///|
/// Serve HTTP/1.1 on 127.0.0.1:`port` from synchronous code: drives the
/// async runtime's event loop until the process is interrupted.
///
/// Error behavior: request parsing happens inside the runtime before user
/// code runs, and a synchronous handler cannot raise (MoonBit's type system
/// rejects raising functions where `(Context) -> Context` is expected), so
/// the bridge only ever sees parsed requests and non-raising failures.
/// Should anything still fail, the runtime aborts only the affected
/// connection (`allow_failure=true`) and the server keeps serving.
/// `Response::internal_error()` is available for explicit 500 responses.
pub fn serve(port : Int, handler : (Request) -> Response) -> Unit {
  @async.run_async_main(async fn() {
    serve_async(port, handler) catch {
      err =>
        eprintln("moonway: failed to start server on 127.0.0.1:\{port}: \{err}")
    }
  })
}
