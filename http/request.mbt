///|
pub(all) struct Request {
  verb : String
  path : String
  /// Raw query string without the leading `?` (empty when absent).
  query : String
  headers : Array[(String, String)]
  body : String
}

///|
pub fn Request::new(verb : String, path : String) -> Request {
  let split = split_query(path)
  { verb, path: split.0, query: split.1, headers: [], body: "", }
}

///|
/// Copy of the request with `body` replaced (query and headers kept).
pub fn Request::with_body(self : Request, body : String) -> Request {
  {
    verb: self.verb,
    path: self.path,
    query: self.query,
    headers: self.headers,
    body,
  }
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

///|
/// Look up a query-string parameter by name (percent-decoded).
pub fn Request::query_param(self : Request, name : String) -> String? {
  query_param(self.query, name)
}

///|
fn split_query(target : String) -> (String, String) {
  let mut at = -1
  let mut i = 0
  for ch in target {
    if ch == '?' {
      at = i
      break
    }
    i = i + 1
  }
  if at < 0 {
    (target, "")
  } else {
    (target[:at].to_owned(), target[at + 1:].to_owned())
  }
}

///|
fn encode_utf8_bytes(s : String) -> Bytes {
  @encoding.encode(UTF8, s)
}

///|
fn decode_utf8_bytes(b : Bytes) -> String {
  let sb = StringBuilder()
  @encoding.decode_to(b[:], sb, encoding=UTF8) catch {
    _err => ()
  }
  sb.to_string()
}

///|
/// Decode "name=value" into its two URL-decoded parts.
fn decode_pair(text : String) -> (String, String) {
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
    (decode_url_encoded(text), "")
  } else {
    (
      decode_url_encoded(text[:at].to_owned()),
      decode_url_encoded(text[at + 1:].to_owned()),
    )
  }
}

///|
/// First value of `name` in a query/form string ("a=1&b=2"), decoded.
pub fn query_param(source : String, name : String) -> String? {
  for pair in source.split("&") {
    let text = pair.to_owned()
    let decoded = decode_pair(text)
    if decoded.0 == name {
      return Some(decoded.1)
    }
  }
  None
}

///|
/// Decode a URL-encoded string: '+' becomes space, %XX becomes the byte.
pub fn decode_url_encoded(s : String) -> String {
  let chars : Array[Byte] = []
  let bytes = encode_utf8_bytes(s)
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let b = bytes[i]
    if b == 37 && i + 2 < len {
      match hex_value(bytes[i + 1], bytes[i + 2]) {
        Some(v) => {
          chars.push(v)
          i = i + 3
        }
        None => {
          chars.push(b)
          i = i + 1
        }
      }
    } else if b == 43 {
      chars.push(32)
      i = i + 1
    } else {
      chars.push(b)
      i = i + 1
    }
  }
  decode_utf8_bytes(Bytes::from_iter(chars.iter()))
}

///|
fn hex_value(high : Byte, low : Byte) -> Byte? {
  let h = hex_digit(high)
  let l = hex_digit(low)
  match (h, l) {
    (Some(hh), Some(ll)) => Some(hh * 16 + ll)
    _ => None
  }
}

///|
fn hex_digit(b : Byte) -> Byte? {
  if b >= 48 && b <= 57 {
    Some(b - 48)
  } else if b >= 65 && b <= 70 {
    Some(b - 55)
  } else if b >= 97 && b <= 102 {
    Some(b - 87)
  } else {
    None
  }
}
