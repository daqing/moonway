///|
pub fn App::listen(self : App, port : Int) -> Unit {
  @http.serve(port, fn(request) { self.dispatch(request) })
}

///|
pub fn App::dispatch(self : App, request : @http.Request) -> @http.Response {
  self.run(request).response
}

///|
pub fn App::handle(
  self : App,
  verb : String,
  path : String,
  body? : String = "",
) -> @http.Response {
  self.dispatch({ verb, path, headers: [], body, })
}

///|
fn App::run(self : App, request : @http.Request) -> Context {
  let ctx = Context::new(request)
  let ctx = self.run_middlewares(ctx)
  match self.find_route(request.verb, request.path) {
    Some(route) => (route.handler)(ctx)
    None => {
      ctx.response.set_status(404)
      ctx.text("Not Found")
    }
  }
}

///|
fn App::run_middlewares(self : App, ctx : Context) -> Context {
  let mut acc = ctx
  for middleware in self.middlewares {
    acc = middleware(acc)
  }
  acc
}

///|
fn App::find_route(self : App, verb : String, path : String) -> Route? {
  for route in self.routes {
    if route.verb == verb && route.path == path {
      return Some(route)
    }
  }
  None
}
