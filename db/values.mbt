///|
/// Encode a string as UTF-8 bytes for binding as SQL text.
fn encode_utf8(s : String) -> Bytes {
  @encoding.encode(UTF8, s)
}

///|
/// Decode UTF-8 bytes from SQL text into a string.
fn bytes_to_string(b : Bytes) -> String {
  let sb = StringBuilder()
  @encoding.decode_to(b[:], sb, encoding=UTF8) catch {
    _err => ()
  }
  sb.to_string()
}

///|
/// Convert a JSON field value (as produced by ToJson-derived models) into a
/// bindable SQLite value for the given column type. Json null maps to SQL
/// NULL. Mismatched shapes degrade to best-effort conversions — the schema
/// and the struct are expected to agree.
pub fn json_to_sql(j : Json, col_type : ColumnType) -> @sqlite.SqlValue? {
  match j {
    Null => None
    True => bool_to_sql(true, col_type)
    False => bool_to_sql(false, col_type)
    Number(n, ..) =>
      match col_type {
        IntT => Some(@sqlite.Int(n.to_int()))
        RealT => Some(@sqlite.Double(n))
        BoolT => Some(@sqlite.Int(if n != 0.0 { 1 } else { 0 }))
        TextT => Some(@sqlite.Text(encode_utf8(n.to_string())))
      }
    String(s) =>
      match col_type {
        IntT => Some(@sqlite.Int(string_to_int(s)))
        RealT => Some(@sqlite.Double(string_to_double(s)))
        BoolT => Some(@sqlite.Int(if s == "true" || s == "1" { 1 } else { 0 }))
        TextT => Some(@sqlite.Text(encode_utf8(s)))
      }
    Array(_) | Object(_) => Some(@sqlite.Text(encode_utf8(j.stringify())))
  }
}

///|
fn bool_to_sql(b : Bool, col_type : ColumnType) -> @sqlite.SqlValue? {
  match col_type {
    RealT => Some(@sqlite.Double(if b { 1.0 } else { 0.0 }))
    TextT => Some(@sqlite.Text(encode_utf8(if b { "true" } else { "false" })))
    _ => Some(@sqlite.Int(if b { 1 } else { 0 }))
  }
}

///|
/// Convert a SQLite column value back into JSON (for FromJson-derived
/// models), honoring the column type — BoolT columns become JSON booleans.
pub fn sql_to_json(v : @sqlite.SqlValue, col_type : ColumnType) -> Json {
  match v {
    Null => Json::null()
    Int(i) =>
      match col_type {
        BoolT => Json(i != 0)
        _ => Json(i)
      }
    Int64(i) =>
      match col_type {
        BoolT => Json(i != 0L)
        _ => Json(i.to_double())
      }
    Double(d) => Json(d)
    Text(b) => Json(bytes_to_string(b))
    Blob(b) => Json(bytes_to_string(b))
  }
}

///|
/// Best-effort numeric parse for string values landing in numeric columns.
fn string_to_int(s : String) -> Int {
  match (@json.parse(s) catch { _err => Json::null() }) {
    Number(n, ..) => n.to_int()
    _ => 0
  }
}

///|
fn string_to_double(s : String) -> Double {
  match (@json.parse(s) catch { _err => Json::null() }) {
    Number(n, ..) => n
    _ => 0.0
  }
}
