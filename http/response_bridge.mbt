///|
async fn Response::write_to(
  self : Response,
  conn : @async_http.ServerConnection,
) -> Unit {
  let extra : Map[@async_http.CaseInsensitiveString, String] = Map([])
  for pair in self.resp_headers {
    extra[@async_http.CaseInsensitiveString(pair.0)] = pair.1
  }
  conn.send_response(
    self.status_code,
    reason_of(self.status_code),
    extra_headers=extra,
  )
  conn.write(self.resp_body)
  conn.end_response()
}

///|
fn reason_of(code : Int) -> String {
  match code {
    200 => "OK"
    201 => "Created"
    202 => "Accepted"
    204 => "No Content"
    301 => "Moved Permanently"
    302 => "Found"
    304 => "Not Modified"
    400 => "Bad Request"
    401 => "Unauthorized"
    403 => "Forbidden"
    404 => "Not Found"
    405 => "Method Not Allowed"
    409 => "Conflict"
    415 => "Unsupported Media Type"
    422 => "Unprocessable Entity"
    429 => "Too Many Requests"
    500 => "Internal Server Error"
    501 => "Not Implemented"
    502 => "Bad Gateway"
    503 => "Service Unavailable"
    504 => "Gateway Timeout"
    _ => "Unknown"
  }
}
