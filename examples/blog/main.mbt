///|
/// The reference blog app: models, routes, Redis cache, WebSocket chat,
/// the admin dashboard and a static page — every moonway feature in one
/// place. Run it from this directory (so the static folder resolves):
///
///   cd examples/blog && moon run examples/blog
///
/// Then open http://localhost:3000. Redis is optional: without it the app
/// simply runs without caching.
async fn main {
  let app = @moonway.new()
  let db = @moonway.sqlite("app.db")
  if !db.migrate([@db.migration(1, "create posts", [posts.create_sql()])]) {
    abort("blog: migrations failed")
  }
  // Posts API
  app.get("/posts", ctx => {
    let items : Array[Json] = db.select_raw(posts, "1=1", [], limit=100)
    ctx.json(Json::array(items))
  })
  app.post("/posts", ctx => {
    let row : Json? = Some(@json.parse(ctx.body())) catch { _err => None }
    match row {
      Some(Object(fields)) =>
        if db.insert_raw(posts, fields) {
          ctx.status(201).json(Json::object(fields))
        } else {
          ctx.status(500).text("insert failed")
        }
      _ => ctx.status(400).text("invalid JSON body")
    }
  })
  // Admin dashboard (http://localhost:3000/admin)
  app.admin(db, [posts])
  // WebSocket chat
  let hub = @moonway.WsHub::new()
  app.ws("/chat", {
    on_message: async fn(_conn, text) { hub.broadcast(text) },
    on_close: async fn(conn) { hub.leave(conn) },
  })
  // Static page
  app.get("/", ctx => ctx.html(home_page()))
  // Serve: with Redis as a response cache when available, plain otherwise.
  // Inside an async main, call the async serving entrypoints directly —
  // app.listen() is the synchronous-main wrapper.
  let handler = fn(request) { app.dispatch(request) }
  let ws_routes = app.ws_routes
  try {
    let client = @cache.RedisClient::connect("127.0.0.1:6379")
    let policy : @http.CachePolicy[@cache.RedisClient] = {
      store: client,
      prefix: "blog",
      ttl: 60,
    }
    @http.serve_cached_async(policy, 3000, handler, ws_routes~)
  } catch {
    _err => {
      eprintln("blog: redis not available, running without cache")
      @http.serve_async(3000, handler, ws_routes~)
    }
  }
}

///|
let posts : @db.Table = @db.table("posts", [
  @db.column("id", @db.IntT, primary=true),
  @db.column("title", @db.TextT),
  @db.column("body", @db.TextT),
])

///|
fn home_page() -> String {
  let lines = [
    "<!doctype html>", "<html>", "  <head><meta charset=\"utf-8\" /><title>moonway blog</title></head>",
    "  <body>", "    <h1>moonway blog</h1>", "    <ul>", "      <li><a href=\"/posts\">posts API</a> (GET/POST JSON)</li>",
    "      <li><a href=\"/admin\">admin dashboard</a></li>", "      <li>WebSocket chat: connect to <code>ws://localhost:3000/chat</code></li>",
    "    </ul>", "  </body>", "</html>",
  ]
  let mut out = ""
  for i, line in lines {
    if i > 0 {
      out = out + "\n"
    }
    out = out + line
  }
  out
}
