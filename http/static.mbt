///|
/// Content-Type for a static file path, by extension. Unknown extensions
/// default to application/octet-stream.
pub fn content_type_for(path : String) -> String {
  let lower = path.to_lower()
  if lower.has_suffix(".html") || lower.has_suffix(".htm") {
    "text/html; charset=utf-8"
  } else if lower.has_suffix(".js") || lower.has_suffix(".mjs") {
    "text/javascript; charset=utf-8"
  } else if lower.has_suffix(".css") {
    "text/css; charset=utf-8"
  } else if lower.has_suffix(".json") || lower.has_suffix(".map") {
    "application/json"
  } else if lower.has_suffix(".svg") {
    "image/svg+xml"
  } else if lower.has_suffix(".png") {
    "image/png"
  } else if lower.has_suffix(".jpg") || lower.has_suffix(".jpeg") {
    "image/jpeg"
  } else if lower.has_suffix(".gif") {
    "image/gif"
  } else if lower.has_suffix(".ico") {
    "image/x-icon"
  } else if lower.has_suffix(".txt") {
    "text/plain; charset=utf-8"
  } else if lower.has_suffix(".woff") {
    "font/woff"
  } else if lower.has_suffix(".woff2") {
    "font/woff2"
  } else {
    "application/octet-stream"
  }
}

///|
/// Reject path-traversal attempts before touching the filesystem.
fn static_path_safe(url_path : String) -> Bool {
  let mut previous = ""
  for segment in url_path.split("/") {
    let part = segment.to_owned()
    if part == ".." {
      return false
    }
    ignore(part)
    ignore(previous)
    previous = part
  }
  true
}

///|
/// Resolve a GET URL path to a file inside `dir`: `/` maps to
/// `/index.html`; directories resolve to their `index.html`. Returns None
/// when nothing matches or the path tries to escape `dir`.
pub fn resolve_static(dir : String, url_path : String) -> String? raise {
  if !static_path_safe(url_path) {
    return None
  }
  let relative = if url_path == "/" { "/index.html" } else { url_path }
  let full = if dir.has_suffix("/") {
    dir + relative[1:].to_owned()
  } else {
    dir + relative
  }
  if @fs.path_exists(full) && @fs.is_file(full) {
    Some(full)
  } else if @fs.path_exists(full + "/index.html") {
    Some(full + "/index.html")
  } else {
    None
  }
}

///|
/// Serve a GET request from `dir`. Returns None when no file matches so
/// the caller can fall back (404 or dynamic dispatch). Read errors degrade
/// to None. Text content types are served through the string body; binary
/// types through the bytes body.
pub fn serve_static_file(dir : String, url_path : String) -> Response? {
  let full = resolve_static(dir, url_path) catch { _err => return None }
  match full {
    Some(path) => {
      let content_type = content_type_for(path)
      let resp = Response::new()
      resp.set_header("Content-Type", content_type)
      let textual = content_type.has_prefix("text/") ||
        content_type == "application/json" ||
        content_type == "image/svg+xml"
      if textual {
        let text = @fs.read_file_to_string(path) catch { _err => return None }
        resp.set_body(text)
      } else {
        let bytes = @fs.read_file_to_bytes(path) catch { _err => return None }
        resp.set_body_bytes(bytes)
      }
      Some(resp)
    }
    None => None
  }
}
