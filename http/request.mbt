///|
pub(all) struct Request {
  verb : String
  path : String
  headers : Array[(String, String)]
  body : String
}

///|
pub fn Request::new(verb : String, path : String) -> Request {
  { verb, path, headers: [], body: "", }
}

///|
pub fn Request::header(self : Request, name : String) -> String? {
  let mut found : String? = None
  for entry in self.headers {
    if entry.0 == name {
      found = Some(entry.1)
    }
  }
  found
}
