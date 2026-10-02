///|
pub fn App::listen(self : App, port : Int) -> Unit {
  let handler = fn(request) { self.dispatch(request) }
  match self.cache_policy {
    Some(policy) =>
      @http.serve_cached(policy, port, handler, ws_routes=self.ws_routes)
    None => @http.serve(port, handler, ws_routes=self.ws_routes)
  }
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
  match self.find_route(request.verb, request.path) {
    Some((route, params)) => {
      for name, value in params {
        ctx.params[name] = value
      }
      let ctx = self.run_middlewares(ctx)
      if !ctx.halted {
        (route.handler)(ctx)
      } else {
        ctx
      }
    }
    None => {
      let ctx = self.run_middlewares(ctx)
      if !ctx.halted {
        self.not_allowed_or_not_found(ctx)
      } else {
        ctx
      }
    }
  }
}

///|
fn App::not_allowed_or_not_found(self : App, ctx : Context) -> Context {
  let verbs = self.allowed_verbs(ctx.path())
  if verbs.length() > 0 {
    let mut allow = ""
    for i, verb in verbs {
      if i > 0 {
        allow = allow + ", "
      }
      allow = allow + verb
    }
    ctx.response.set_status(405)
    let ctx = ctx.header("Allow", allow)
    ctx.text("Method Not Allowed")
  } else {
    ctx.response.set_status(404)
    ctx.text("Not Found")
  }
}

///|
fn App::run_middlewares(self : App, ctx : Context) -> Context {
  let mut acc = ctx
  for middleware in self.middlewares {
    if acc.halted {
      break
    }
    acc = middleware(acc)
  }
  acc
}
