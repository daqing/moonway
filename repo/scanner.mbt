///|
fn Executor::scan_records(
  self : Executor,
  prepared : Prepared,
) -> Array[Record] raise RepoError {
  let stmt = self.prepare_statement(prepared)
  let records : Array[Record] = []
  for row in stmt.iter() {
    let record : Record = Map([])
    for index in 0..<row.column_count() {
      record[row.column_name(index)] = sql_to_value(row.column(index))
    }
    records.push(record)
  }
  stmt.finalize()
  records
}

///|
fn[T : FromJson] decode_record(
  schema : @db.Table,
  record : Record,
) -> T raise RepoError {
  let fields : Map[String, Json] = Map([])
  for name, value in record {
    match column_named(schema, name) {
      Some(column) => fields[name] = value_to_json_typed(value, column.col_type)
      None => raise RepoError::MissingDestination(name)
    }
  }
  @json.from_json(Json::object(fields)) catch {
    _ => raise RepoError::DecodeFailed("cannot decode " + schema.name + " row")
  }
}

///|
fn column_named(schema : @db.Table, name : String) -> @db.Column? {
  for column in schema.columns {
    if column.name == name {
      return Some(column)
    }
  }
  None
}

///|
fn value_to_json_typed(
  value : @sql.Value,
  column_type : @db.ColumnType,
) -> Json {
  match (value, column_type) {
    (@sql.Value::Null, _) => Json::null()
    (@sql.Value::Int(value), @db.ColumnType::BoolT) => Json(value != 0)
    (@sql.Value::Int64(value), @db.ColumnType::BoolT) => Json(value != 0L)
    (@sql.Value::Real(value), @db.ColumnType::BoolT) => Json(value != 0.0)
    (@sql.Value::Text(value), @db.ColumnType::BoolT) =>
      Json(value == "true" || value == "1")
    (@sql.Value::Int64(value), _) => Json(value.to_double())
    _ => value_to_json(value)
  }
}

///|
pub fn record_to_json(record : Record) -> Json {
  value_to_json(@sql.Value::Object(record))
}
