///|
/// Serve HTTP/1.1 on 127.0.0.1:`port`, bridging the async runtime's server
/// to the synchronous `handler`. Blocks until the process is interrupted.
pub fn serve(port : Int, handler : (Request) -> Response) -> Unit {
  @async.run_async_main(async fn() {
    let bound = try? @async_socket.Addr::parse("127.0.0.1:\{port}")
    match bound {
      Ok(addr) => {
        let server = @async_http.Server(addr)
        server.run_forever(async fn(request, body, conn) {
          let body_text = match (try? body.read_all().text()) {
            Ok(text) => text
            Err(_err) => ""
          }
          let req = {
            verb: verb_of(request.meth),
            path: request.path,
            headers: [],
            body: body_text,
          }
          let resp = handler(req)
          conn.send_response(resp.status(), "OK")
          conn.write(resp.body())
          conn.end_response()
        })
      }
      Err(err) => eprintln("moonway: failed to bind 127.0.0.1:\{port}: \{err}")
    }
  })
}

///|
fn verb_of(meth : @async_http.RequestMethod) -> String {
  match meth {
    Get => "GET"
    Head => "HEAD"
    Post => "POST"
    Put => "PUT"
    Delete => "DELETE"
    Connect => "CONNECT"
    Options => "OPTIONS"
    Trace => "TRACE"
    Patch => "PATCH"
  }
}
