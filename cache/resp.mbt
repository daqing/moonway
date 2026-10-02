///|
/// A decoded RESP2 reply.
pub(all) enum RespValue {
  Simple(String)
  Error(String)
  Integer(Int64)
  Bulk(String?)
  Array(Array[RespValue])
} derive(Eq, Debug)

///|
pub extend RespValue with Eq::{equal, not_equal}

///|
pub extend RespValue with @debug.Debug::{to_repr}

///|
/// Encode a command as an array of bulk strings (the client request format).
pub fn encode_command(args : Array[String]) -> Bytes {
  let mut out = "*\{args.length()}\r\n"
  for arg in args {
    out = out + "$\{byte_length(arg)}\r\n\{arg}\r\n"
  }
  encode_utf8(out)
}

///|
fn byte_length(s : String) -> Int {
  @encoding.encode(UTF8, s).length()
}

///|
fn encode_utf8(s : String) -> Bytes {
  @encoding.encode(UTF8, s)
}

///|
/// Decode UTF-8 bytes into a string (lossy on invalid input).
fn bytes_to_string(b : BytesView) -> String {
  let sb = StringBuilder()
  @encoding.decode_to(b, sb, encoding=UTF8) catch {
    _err => ()
  }
  sb.to_string()
}

///|
/// Outcome of trying to decode one reply from a buffer.
pub(all) enum Decoded {
  /// A complete reply and the number of bytes it consumed.
  Complete(RespValue, Int)
  /// The buffer does not yet hold a full reply.
  Incomplete
  /// The buffer starts with a syntactically invalid reply.
  Malformed(String)
} derive(Eq, Debug)

///|
pub extend Decoded with Eq::{equal, not_equal}

///|
pub extend Decoded with @debug.Debug::{to_repr}

///|
/// Try to decode a single RESP2 reply from the front of `buf`.
pub fn decode(buf : Bytes) -> Decoded {
  if buf.length() == 0 {
    return Incomplete
  }
  match buf[0] {
    43 =>
      match line_text(buf, 1) {
        Some((message, consumed)) => Complete(Simple(message), consumed)
        None => Incomplete
      }
    45 =>
      match line_text(buf, 1) {
        Some((message, consumed)) => Complete(Error(message), consumed)
        None => Incomplete
      }
    58 =>
      match line_text(buf, 1) {
        Some((message, consumed)) =>
          match parse_int(message) {
            Some(n) => Complete(Integer(n), consumed)
            None => Malformed("invalid integer reply")
          }
        None => Incomplete
      }
    36 => decode_bulk(buf)
    42 => decode_array(buf)
    first => Malformed("unknown reply type \{first.to_int()}")
  }
}

///|
/// The text of a line reply (after the type byte, before CRLF) and the
/// total number of bytes from `start`... consumed from the buffer start
/// including the CRLF.
fn line_text(buf : Bytes, start : Int) -> (String, Int)? {
  match find_crlf(buf, start) {
    Some(at) => Some((bytes_to_string(buf[start:at]), at + 2))
    None => None
  }
}

///|
fn decode_bulk(buf : Bytes) -> Decoded {
  match find_crlf(buf, 1) {
    None => Incomplete
    Some(at) =>
      match parse_int(bytes_to_string(buf[1:at])) {
        None => Malformed("invalid bulk length")
        Some(-1L) => Complete(Bulk(None), at + 2)
        Some(length) => {
          let len = length.to_int()
          let body = at + 2
          if len < 0 {
            Malformed("negative bulk length")
          } else if buf.length() < body + len + 2 {
            Incomplete
          } else {
            Complete(
              Bulk(Some(bytes_to_string(buf[body:body + len]))),
              body + len + 2,
            )
          }
        }
      }
  }
}

///|
fn decode_array(buf : Bytes) -> Decoded {
  match find_crlf(buf, 1) {
    None => Incomplete
    Some(at) =>
      match parse_int(bytes_to_string(buf[1:at])) {
        None => Malformed("invalid array length")
        Some(-1L) => Complete(Array([]), at + 2)
        Some(count) => {
          let n = count.to_int()
          if n < 0 {
            Malformed("negative array length")
          } else {
            decode_array_items(buf, at + 2, n, [])
          }
        }
      }
  }
}

///|
fn decode_array_items(
  buf : Bytes,
  offset : Int,
  remaining : Int,
  collected : Array[RespValue],
) -> Decoded {
  if remaining == 0 {
    return Complete(Array(collected), offset)
  }
  let rest = buf[offset:].to_owned()
  match decode(rest) {
    Incomplete => Incomplete
    Malformed(reason) => Malformed(reason)
    Complete(value, used) => {
      collected.push(value)
      decode_array_items(buf, offset + used, remaining - 1, collected)
    }
  }
}

///|
fn find_crlf(buf : Bytes, from : Int) -> Int? {
  let mut i = from
  while i + 1 < buf.length() {
    if buf[i] == 13 && buf[i + 1] == 10 {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn parse_int(s : String) -> Int64? {
  if s.length() == 0 {
    return None
  }
  let mut negative = false
  let mut value = 0L
  for ch in s {
    if ch == '-' && value == 0L && !negative {
      negative = true
    } else if ch >= '0' && ch <= '9' {
      value = value * 10L + (ch.to_int() - 48).to_int64()
    } else {
      return None
    }
  }
  Some(if negative { -value } else { value })
}
