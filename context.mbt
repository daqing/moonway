///|
pub struct Context {
  request : @http.Request
  params : Map[String, String]
  response : @http.Response
  mut halted : Bool
}

///|
fn Context::new(request : @http.Request) -> Context {
  { request, params: Map([]), response: @http.Response::new(), halted: false, }
}

///|
/// Short-circuit the middleware pipeline: later middlewares and the route
/// handler are skipped, and the response built so far is returned as-is.
pub fn Context::halt(self : Context) -> Context {
  self.halted = true
  self
}

///|
pub fn Context::param(self : Context, name : String) -> String? {
  self.params.get(name)
}

///|
/// Look up a query-string parameter (`?name=value`) by name.
pub fn Context::query_param(self : Context, name : String) -> String? {
  self.request.query_param(name)
}

///|
pub fn Context::verb(self : Context) -> String {
  self.request.verb
}

///|
pub fn Context::path(self : Context) -> String {
  self.request.path
}

///|
pub fn Context::body(self : Context) -> String {
  self.request.body
}

///|
pub fn Context::request_header(self : Context, name : String) -> String? {
  self.request.header(name)
}

///|
pub fn Context::status(self : Context, code : Int) -> Context {
  self.response.set_status(code)
  self
}

///|
pub fn Context::header(
  self : Context,
  name : String,
  value : String,
) -> Context {
  self.response.set_header(name, value)
  self
}

///|
pub fn Context::text(self : Context, body : String) -> Context {
  self.response.set_body(body)
  self.response.set_header("Content-Type", "text/plain; charset=utf-8")
  self
}

///|
pub fn Context::html(self : Context, body : String) -> Context {
  self.response.set_body(body)
  self.response.set_header("Content-Type", "text/html; charset=utf-8")
  self
}

///|
pub fn[T : ToJson] Context::json(self : Context, value : T) -> Context {
  self.response.set_body(value.to_json().stringify())
  self.response.set_header("Content-Type", "application/json")
  self
}
