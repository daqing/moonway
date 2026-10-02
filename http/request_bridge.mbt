///|
fn Request::from_runtime(
  request : @async_http.Request,
  body : String,
) -> Request {
  let headers = []
  for k, v in request.headers {
    headers.push((k.to_string(), v))
  }
  let split = split_query(request.path)
  { verb: verb_of(request.meth), path: split.0, query: split.1, headers, body, }
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
