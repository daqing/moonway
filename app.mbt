///|
pub struct App {
  routes : Array[Route]
  middlewares : Array[(Context) -> Context]
  mut cache_policy : @http.CachePolicy[@cache.RedisClient]?
  ws_routes : Array[@http.WsRoute]
}

///|
pub fn new() -> App {
  { routes: [], middlewares: [], cache_policy: None, ws_routes: [], }
}

///|
/// Enable response caching for GET requests through a Redis client: hits
/// are served before middlewares and handlers (X-Cache: HIT); 200 responses
/// are stored with the configured TTL (X-Cache: MISS). Cache failures
/// degrade to plain dispatch.
pub fn App::cache(
  self : App,
  client : @cache.RedisClient,
  ttl? : Int = 60,
  prefix? : String = "moonway",
) -> Unit {
  self.cache_policy = Some({ store: client, prefix, ttl, })
}

///|
/// Register a middleware. Middlewares run in registration order, before the
/// matched route handler; each receives and returns the context. A
/// middleware may short-circuit the pipeline with `ctx.halt()`: later
/// middlewares and the route handler are skipped.
pub fn App::use(self : App, middleware : (Context) -> Context) -> Unit {
  self.middlewares.push(middleware)
}

///|
pub fn App::get(
  self : App,
  path : String,
  handler : (Context) -> Context,
) -> Unit {
  self.add_route("GET", path, handler)
}

///|
pub fn App::post(
  self : App,
  path : String,
  handler : (Context) -> Context,
) -> Unit {
  self.add_route("POST", path, handler)
}

///|
pub fn App::put(
  self : App,
  path : String,
  handler : (Context) -> Context,
) -> Unit {
  self.add_route("PUT", path, handler)
}

///|
pub fn App::patch(
  self : App,
  path : String,
  handler : (Context) -> Context,
) -> Unit {
  self.add_route("PATCH", path, handler)
}

///|
pub fn App::delete(
  self : App,
  path : String,
  handler : (Context) -> Context,
) -> Unit {
  self.add_route("DELETE", path, handler)
}

///|
fn App::add_route(
  self : App,
  verb : String,
  path : String,
  handler : (Context) -> Context,
) -> Unit {
  self.routes.push({ verb, path, handler, })
}
