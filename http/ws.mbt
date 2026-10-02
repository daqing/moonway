///|
/// A WebSocket route: GET requests whose path matches exactly are upgraded
/// and handed to the handler, which owns the connection until it returns.
pub(all) struct WsRoute {
  path : String
  handler : async (@async_websocket.Conn) -> Unit
}

///|
/// Upgrade and dispatch a request to the matching WebSocket route.
/// Returns false when no route matches (the caller falls back to normal
/// HTTP dispatch).
pub async fn serve_websocket(
  routes : Array[WsRoute],
  request : @async_http.Request,
  conn : @async_http.ServerConnection,
) -> Bool {
  for route in routes {
    if request.path == route.path {
      let ws = @async_websocket.Conn::from_http_server(request, conn)
      (route.handler)(ws) catch {
        err => eprintln("moonway: websocket handler failed: \{err}")
      }
      return true
    }
  }
  false
}
