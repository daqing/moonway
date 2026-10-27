///|
pub type Record = Map[String, @sql.Value]

///|
fn encode_utf8(value : String) -> Bytes {
  @encoding.encode(UTF8, value)
}

///|
fn bytes_to_string(value : Bytes) -> String {
  let output = StringBuilder()
  @encoding.decode_to(value[:], output, encoding=UTF8) catch {
    _ => ()
  }
  output.to_string()
}

///|
fn value_to_sql(value : @sql.Value) -> @sqlite.SqlValue {
  match value {
    Null => @sqlite.Null
    Int(value) => @sqlite.Int(value)
    Int64(value) => @sqlite.Int64(value)
    Real(value) => @sqlite.Double(value)
    Text(value) => @sqlite.Text(encode_utf8(value))
    Bool(value) => @sqlite.Int(if value { 1 } else { 0 })
    Blob(value) => @sqlite.Blob(value)
    Json(value) => @sqlite.Text(encode_utf8(value.stringify()))
    Array(_) | Object(_) =>
      @sqlite.Text(encode_utf8(value_to_json(value).stringify()))
  }
}

///|
fn sql_to_value(value : @sqlite.SqlValue) -> @sql.Value {
  match value {
    Null => @sql.Value::Null
    Int(value) => @sql.Value::Int(value)
    Int64(value) => @sql.Value::Int64(value)
    Double(value) => @sql.Value::Real(value)
    Text(value) => @sql.Value::Text(bytes_to_string(value))
    Blob(value) => @sql.Value::Blob(value)
  }
}

///|
pub fn value_to_json(value : @sql.Value) -> Json {
  match value {
    Null => Json::null()
    Int(value) => Json(value)
    Int64(value) => Json(value)
    Real(value) => Json(value)
    Text(value) => Json(value)
    Bool(value) => Json(value)
    Blob(value) => Json(bytes_to_string(value))
    Json(value) => value
    Array(values) => Json::array(values.map(value_to_json))
    Object(values) => {
      let fields : Map[String, Json] = Map([])
      for key, item in values {
        fields[key] = value_to_json(item)
      }
      Json::object(fields)
    }
  }
}

///|
pub fn value_as_int64(value : @sql.Value) -> Int64? {
  match value {
    Int(value) => Some(value.to_int64())
    Int64(value) => Some(value)
    Real(value) => Some(value.to_int64())
    _ => None
  }
}
