///|
pub struct Route {
  verb : String
  path : String
  handler : (Context) -> Context
}

///|
fn without_query(path : String) -> String {
  match path.split("?").next() {
    Some(first) => first.to_owned()
    None => path
  }
}

///|
/// Split a path into non-empty segments, ignoring any query string.
fn split_path(path : String) -> Array[String] {
  let segments = []
  for segment in without_query(path).split("/") {
    if segment != "" {
      segments.push(segment.to_owned())
    }
  }
  segments
}

///|
/// Try to match a request path against this route's pattern.
/// A `:name` pattern segment captures the actual segment as a parameter.
/// Returns the captured parameters, or None when the shape does not match.
fn Route::try_match(
  self : Route,
  actual : Array[String],
) -> Map[String, String]? {
  let pattern = split_path(self.path)
  if pattern.length() != actual.length() {
    return None
  }
  let params : Map[String, String] = Map([])
  for i, segment in pattern {
    if segment.has_prefix(":") {
      params[segment[1:].to_owned()] = actual[i]
    } else if segment != actual[i] {
      return None
    }
  }
  Some(params)
}

///|
/// Number of literal (non-parameter) segments — the more of them a route
/// has, the more specific it is.
fn Route::specificity(self : Route) -> Int {
  let mut count = 0
  for segment in split_path(self.path) {
    if !segment.has_prefix(":") {
      count = count + 1
    }
  }
  count
}

///|
/// Find the best matching route for a request: shape-compatible routes
/// compete on specificity (static segments win over `:param` captures,
/// registration order breaks ties). Returns the route with its captured
/// parameters.
fn App::find_route(
  self : App,
  verb : String,
  path : String,
) -> (Route, Map[String, String])? {
  let actual = split_path(path)
  let mut best : Route? = None
  let mut best_params : Map[String, String] = Map([])
  let mut best_score = -1
  for route in self.routes {
    if route.verb == verb {
      match route.try_match(actual) {
        Some(params) => {
          let score = route.specificity()
          if score > best_score {
            best = Some(route)
            best_params = params
            best_score = score
          }
        }
        None => ()
      }
    }
  }
  match best {
    Some(route) => Some((route, best_params))
    None => None
  }
}
