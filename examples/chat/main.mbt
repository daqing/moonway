///|
fn main {
  let app = @moonway.new()
  let hub = @moonway.WsHub::new()
  app.get("/", ctx => ctx.html(chat_page()))
  app.ws("/chat", {
    on_message: async fn(conn, text) {
      hub.join(conn)
      hub.broadcast("someone said: \{text}")
    },
    on_close: async fn(conn) { hub.leave(conn) },
  })
  app.listen(3000)
}

///|
fn chat_page() -> String {
  join_lines([
    "<!doctype html>", "<html>", "  <body>", "    <h1>moonway chat</h1>", "    <ul id=\"messages\"></ul>",
    "    <input id=\"box\" placeholder=\"say something\" />", "    <button onclick=\"send()\">Send</button>",
    "    <script>", "      const ws = new WebSocket(\"ws://\" + location.host + \"/chat\");",
    "      ws.onmessage = (e) => {", "        const li = document.createElement(\"li\");",
    "        li.textContent = e.data;", "        document.getElementById(\"messages\").appendChild(li);",
    "      };", "      function send() {", "        const box = document.getElementById(\"box\");",
    "        ws.send(box.value);", "        box.value = \"\";", "      }", "    </script>",
    "  </body>", "</html>",
  ])
}

///|
fn join_lines(lines : Array[String]) -> String {
  let mut out = ""
  for i, line in lines {
    if i > 0 {
      out = out + "\n"
    }
    out = out + line
  }
  out
}
