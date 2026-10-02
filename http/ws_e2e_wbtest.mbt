///|
async test "websocket route upgrades and echoes" {
  @async.with_task_group(async fn(group) {
    group.spawn_bg(
      async fn() {
        serve_async(18097, _req => Response::new(), ws_routes=[
          {
            path: "/ws/echo",
            handler: async fn(conn) {
              while true {
                let message = conn.recv()
                let text = message.read_all().text() catch { _err => "" }
                conn.send_text("echo: \{text}")
              }
            },
          },
        ]) catch {
          err => eprintln("moonway: test server failed: \{err}")
        }
      },
      no_wait=true,
    )
    let client = @async_websocket.Conn::connect("ws://127.0.0.1:18097/ws/echo")
    client.send_text("hello")
    let reply = client.recv()
    let got = reply.read_all().text() catch { _err => "" }
    assert_eq(got, "echo: hello")
    client.send_text("again")
    let reply2 = client.recv()
    let got2 = reply2.read_all().text() catch { _err => "" }
    assert_eq(got2, "echo: again")
    client.close()
  })
}
