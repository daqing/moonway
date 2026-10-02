///|
/// Escape text for safe inclusion in HTML content and attribute values.
pub fn escape_html(s : String) -> String {
  let mut out = ""
  for ch in s {
    let replacement : String? = match ch {
      '&' => Some("&amp;")
      '<' => Some("&lt;")
      '>' => Some("&gt;")
      '"' => Some("&quot;")
      '\'' => Some("&#39;")
      _ => None
    }
    match replacement {
      Some(entity) => out = out + entity
      None => out = out + ch.to_string()
    }
  }
  out
}

///|
/// Display a JSON cell value as plain text (strings without quotes).
pub fn display_value(v : Json) -> String {
  match v {
    String(s) => escape_html(s)
    Null => ""
    other => escape_html(other.stringify())
  }
}

///|
/// Parse an application/x-www-form-urlencoded body into a field map.
/// Values are URL-decoded; repeated keys keep the last value.
pub fn form_decode(body : String) -> Map[String, String] {
  let fields : Map[String, String] = Map([])
  for pair in body.split("&") {
    let text = pair.to_owned()
    let mut at = -1
    let mut i = 0
    for ch in text {
      if ch == '=' {
        at = i
        break
      }
      i = i + 1
    }
    if at < 0 {
      fields[decode(text)] = ""
    } else {
      fields[decode(text[:at].to_owned())] = decode(text[at + 1:].to_owned())
    }
  }
  fields
}

///|
fn decode(s : String) -> String {
  @http.decode_url_encoded(s)
}
