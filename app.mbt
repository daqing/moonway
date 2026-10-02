///|
pub struct App {
  routes : Array[Route]
  middlewares : Array[(Context) -> Context]
}

///|
pub fn new() -> App {
  { routes: [], middlewares: [], }
}

///|
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
