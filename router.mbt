///|
pub struct Route {
  verb : String
  path : String
  handler : (Context) -> Context
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
