///|
async test "app.ws serves events and the hub broadcasts" {
  let app = new()
  let hub = WsHub::new()
  app.ws("/chat", {
    on_message: async fn(conn, text) {
      hub.join(conn)
      hub.broadcast("got: \{text}")
    },
    on_close: fn(conn) { hub.leave(conn) },
  })
  @async.with_task_group(async fn(group) {
    group.spawn_bg(
      async fn() {
        @http.serve_async(
          18098,
          _req => @http.Response::new(),
          ws_routes=app.ws_routes,
        ) catch {
          err => eprintln("moonway: test server failed: \{err}")
        }
      },
      no_wait=true,
    )
    let alice = @async_websocket.Conn::connect("ws://127.0.0.1:18098/chat")
    alice.send_text("one")
    let reply1 = alice.recv()
    assert_eq(reply1.read_all().text(), "got: one")
    let bob = @async_websocket.Conn::connect("ws://127.0.0.1:18098/chat")
    bob.send_text("two")
    let reply_bob = bob.recv()
    assert_eq(reply_bob.read_all().text(), "got: two")
    let reply_alice = alice.recv()
    assert_eq(reply_alice.read_all().text(), "got: two")
    alice.close()
    bob.close()
  })
}
