///|
pub struct Context {
  request : @http.Request
  params : Map[String, String]
  response : @http.Response
}

///|
fn Context::new(request : @http.Request) -> Context {
  { request, params: Map([]), response: @http.Response::new(), }
}

///|
pub fn Context::param(self : Context, name : String) -> String? {
  self.params.get(name)
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
