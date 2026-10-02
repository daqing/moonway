///|
fn Request::from_runtime(
  request : @async_http.Request,
  body : String,
) -> Request {
  let headers = []
  for k, v in request.headers {
    headers.push((k.to_string(), v))
  }
  { verb: verb_of(request.meth), path: request.path, headers, body, }
}

///|
fn verb_of(meth : @async_http.RequestMethod) -> String {
  match meth {
    Get => "GET"
    Head => "HEAD"
    Post => "POST"
    Put => "PUT"
    Delete => "DELETE"
    Connect => "CONNECT"
    Options => "OPTIONS"
    Trace => "TRACE"
    Patch => "PATCH"
  }
}
