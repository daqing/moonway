///|
/// Core serving loop. Must run inside the async runtime (an async fn main,
/// or a task spawned within one). Binds `host`:`port` (default host `127.0.0.1`); raises on bind
/// failure. GET requests matching a WebSocket route are upgraded instead of
/// dispatched.
pub async fn serve_async(
  port : Int32,
  handler : (Request) -> Response,
  ws_routes~ : Array[WsRoute] = [],
  host~ : String = "127.0.0.1",
) -> Unit {
  let addr = @async_socket.Addr::parse("\{host}:\{port}")
  let server = @async_http.Server(addr, reuse_addr=true)
  server.run_forever(
    async fn(request, body, conn) {
      if serve_websocket(ws_routes, request, conn) {
        return
      }
      let body_text = body.read_all().text() catch { _err => "" }
      let resp = handler(Request::from_runtime(request, body_text))
      resp.write_to(conn)
    },
    allow_failure=true,
  )
}

///|
/// Serving loop with response caching for GET requests: hits are answered
/// before dispatch (`X-Cache: HIT`) and 200 responses are stored with the
/// policy's TTL (`X-Cache: MISS`). Cache failures degrade to plain dispatch.
pub async fn[S : CacheStore] serve_cached_async(
  policy : CachePolicy[S],
  port : Int32,
  handler : (Request) -> Response,
  ws_routes~ : Array[WsRoute] = [],
  host~ : String = "127.0.0.1",
) -> Unit {
  let addr = @async_socket.Addr::parse("\{host}:\{port}")
  let server = @async_http.Server(addr, reuse_addr=true)
  server.run_forever(
    async fn(request, body, conn) {
      if serve_websocket(ws_routes, request, conn) {
        return
      }
      let body_text = body.read_all().text() catch { _err => "" }
      let req = Request::from_runtime(request, body_text)
      let resp = if req.verb == "GET" {
        serve_one(policy, req, handler)
      } else {
        handler(req)
      }
      resp.write_to(conn)
    },
    allow_failure=true,
  )
}

///|
/// Controls the stderr warnings emitted when the cache backend fails
/// (`cache unavailable, ...`). Enabled by default; disable to run quietly,
/// e.g. in tests that exercise cache degradation.
pub fn set_cache_warnings(enabled : Bool) -> Unit {
  cache_warnings.val = enabled
}

///|
let cache_warnings : Ref[Bool] = Ref(true)

///|
/// Cache lookup or dispatch-plus-store for one GET request. Any cache
/// failure degrades to a plain dispatch.
async fn[S : CacheStore] serve_one(
  policy : CachePolicy[S],
  req : Request,
  handler : (Request) -> Response,
) -> Response {
  let cached = policy.lookup(req.path) catch {
    err => {
      if cache_warnings.val {
        eprintln("moonway: cache unavailable, serving without cache: \{err}")
      }
      None
    }
  }
  match cached {
    Some(hit) => {
      let resp = Response::new()
      resp.set_status(200)
      resp.set_header("X-Cache", "HIT")
      resp.set_header("Content-Type", hit.content_type)
      resp.set_body(hit.body)
      resp
    }
    None => {
      let resp = handler(req)
      if resp.status() == 200 {
        let content_type = resp.header("Content-Type").unwrap_or("text/plain")
        let payload : CachedResponse = { content_type, body: resp.body(), }
        let stored = try {
          policy.store(req.path, payload)
          true
        } catch {
          err => {
            if cache_warnings.val {
              eprintln(
                "moonway: cache unavailable, response not cached: \{err}",
              )
            }
            false
          }
        }
        if stored {
          resp.set_header("X-Cache", "MISS")
        }
      }
      resp
    }
  }
}

///|
/// Serve HTTP/1.1 on `host`:`port` (default host `127.0.0.1`) from synchronous code: drives the
/// async runtime's event loop until the process is interrupted.
///
/// Error behavior: request parsing happens inside the runtime before user
/// code runs, and a synchronous handler cannot raise (MoonBit's type system
/// rejects raising functions where `(Context) -> Context` is expected), so
/// the bridge only ever sees parsed requests and non-raising failures.
/// Should anything still fail, the runtime aborts only the affected
/// connection (`allow_failure=true`) and the server keeps serving.
/// `Response::internal_error()` is available for explicit 500 responses.
pub fn serve(
  port : Int32,
  handler : (Request) -> Response,
  ws_routes~ : Array[WsRoute] = [],
  host~ : String = "127.0.0.1",
) -> Unit {
  @async.run_async_main(async fn() {
    serve_async(port, handler, ws_routes~, host~) catch {
      err =>
        eprintln("moonway: failed to start server on \{host}:\{port}: \{err}")
    }
  })
}

///|
/// Like `serve`, with response caching bound to a concrete cache store.
pub fn[S : CacheStore] serve_cached(
  policy : CachePolicy[S],
  port : Int32,
  handler : (Request) -> Response,
  ws_routes~ : Array[WsRoute] = [],
  host~ : String = "127.0.0.1",
) -> Unit {
  @async.run_async_main(async fn() {
    serve_cached_async(policy, port, handler, ws_routes~, host~) catch {
      err =>
        eprintln("moonway: failed to start server on \{host}:\{port}: \{err}")
    }
  })
}
