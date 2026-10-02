///|
let ws_conn_counter : Ref[Int] = Ref(0)

///|
fn fresh_ws_id() -> Int {
  ws_conn_counter.val = ws_conn_counter.val + 1
  ws_conn_counter.val
}

///|
/// A WebSocket connection handed to user handlers.
pub struct WsConn {
  conn : @async_websocket.Conn
  id : Int
}

///|
/// Receive the next message as text. Binary messages are decoded lossily.
/// Raises when the connection closes.
pub async fn WsConn::recv_text(self : WsConn) -> String {
  let message = self.conn.recv()
  message.read_all().text() catch {
    _err => ""
  }
}

///|
/// Send a text message.
pub async fn WsConn::send_text(self : WsConn, text : String) -> Unit {
  self.conn.send_text(text)
}

///|
/// Close the connection politely.
pub async fn WsConn::close(self : WsConn) -> Unit {
  self.conn.send_close()
}

///|
/// Event handlers for a WebSocket connection. The framework runs the
/// receive loop: `on_message` fires per text message, and `on_close` fires
/// exactly once when the connection closes or errors.
pub(all) struct WsHandler {
  on_message : async (WsConn, String) -> Unit
  on_close : async (WsConn) -> Unit
}

///|
/// A broadcast hub: register connections as they open and broadcast text to
/// all of them. Runs inside the single-threaded event loop, so no locking
/// is needed. Failed sends are dropped silently.
pub struct WsHub {
  conns : Array[WsConn]
}

///|
pub fn WsHub::new() -> WsHub {
  { conns: [], }
}

///|
pub fn WsHub::join(self : WsHub, conn : WsConn) -> Unit {
  self.conns.push(conn)
}

///|
pub fn WsHub::leave(self : WsHub, conn : WsConn) -> Unit {
  let mut at = -1
  for i, candidate in self.conns {
    if candidate.id == conn.id {
      at = i
    }
  }
  if at >= 0 {
    let _ = self.conns.remove(at)
  }
}

///|
pub async fn WsHub::broadcast(self : WsHub, text : String) -> Unit {
  for conn in self.conns {
    conn.send_text(text) catch {
      _err => ()
    }
  }
}

///|
/// Register a WebSocket route: connections to `path` are upgraded and the
/// framework runs the receive loop, invoking the handler's events.
pub fn App::ws(self : App, path : String, handler : WsHandler) -> Unit {
  self.ws_routes.push({
    path,
    handler: async fn(conn) {
      let wc : WsConn = { conn, id: fresh_ws_id(), }
      try {
        while true {
          let text = wc.recv_text()
          (handler.on_message)(wc, text)
        }
      } catch {
        _closed => (handler.on_close)(wc) catch { _err => () }
      }
    },
  })
}

///|
/// Drive the event loop of a single WebSocket connection with a handler.
/// Used by `App::ws`; exposed for tests and custom serving setups.
pub async fn run_ws(handler : WsHandler, conn : @async_websocket.Conn) -> Unit {
  let wc : WsConn = { conn, id: fresh_ws_id(), }
  try {
    while true {
      let text = wc.recv_text()
      (handler.on_message)(wc, text)
    }
  } catch {
    _closed => (handler.on_close)(wc) catch { _err => () }
  }
}
