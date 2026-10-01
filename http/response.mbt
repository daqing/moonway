///|
pub struct Response {
  mut status_code : Int
  resp_headers : Array[(String, String)]
  mut resp_body : String
}

///|
pub fn Response::new() -> Response {
  { status_code: 200, resp_headers: [], resp_body: "", }
}

///|
pub fn Response::set_status(self : Response, status : Int) -> Unit {
  self.status_code = status
}

///|
pub fn Response::set_header(
  self : Response,
  name : String,
  value : String,
) -> Unit {
  self.resp_headers.push((name, value))
}

///|
pub fn Response::set_body(self : Response, body : String) -> Unit {
  self.resp_body = body
}

///|
pub fn Response::status(self : Response) -> Int {
  self.status_code
}

///|
pub fn Response::body(self : Response) -> String {
  self.resp_body
}

///|
pub fn Response::headers(self : Response) -> Array[(String, String)] {
  self.resp_headers
}

///|
pub fn Response::header(self : Response, name : String) -> String? {
  let mut found : String? = None
  for entry in self.resp_headers {
    if entry.0 == name {
      found = Some(entry.1)
    }
  }
  found
}
