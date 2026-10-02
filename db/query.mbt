///|
fn Table::insert_sql(self : Table) -> String {
  let mut cols = ""
  let mut marks = ""
  for i, col in self.columns {
    if i > 0 {
      cols = cols + ", "
      marks = marks + ", "
    }
    cols = cols + quote_ident(col.name)
    marks = marks + "?"
  }
  "INSERT INTO " +
  quote_ident(self.name) +
  " (" +
  cols +
  ") VALUES (" +
  marks +
  ")"
}

///|
fn Table::select_sql(self : Table, where_clause : String) -> String {
  "SELECT " +
  column_list(self) +
  " FROM " +
  quote_ident(self.name) +
  " WHERE " +
  where_clause
}

///|
fn column_list(t : Table) -> String {
  let mut cols = ""
  for i, col in t.columns {
    if i > 0 {
      cols = cols + ", "
    }
    cols = cols + quote_ident(col.name)
  }
  cols
}

///|
fn primary_column(t : Table) -> Column? {
  for col in t.columns {
    if col.primary {
      return Some(col)
    }
  }
  None
}

///|
fn bind_row(stmt : @sqlite.Statement, t : Table, row_json : Json) -> Unit {
  let values : Array[@sqlite.SqlValue] = []
  for col in t.columns {
    let value = match row_json {
      Object(fields) =>
        match fields.get(col.name) {
          Some(field_json) => json_to_sql(field_json, col.col_type)
          None => None
        }
      _ => None
    }
    values.push(
      match value {
        Some(sql_value) => sql_value
        None => @sqlite.Null
      },
    )
  }
  stmt.bind_all(values) |> ignore
}

///|
fn[T : FromJson] decode_row(t : Table, row : @sqlite.Statement) -> T? {
  let fields : Map[String, Json] = Map([])
  for i, col in t.columns {
    fields[col.name] = sql_to_json(row.column(i), col.col_type)
  }
  Some(@json.from_json(Json::object(fields))) catch {
    _err => None
  }
}

///|
/// Insert a model value into the table. Fields come from the value's
/// ToJson representation, converted per the column types; fields without a
/// matching column are ignored, columns without a matching field bind NULL.
pub fn[T : ToJson] Database::insert(
  self : Database,
  t : Table,
  value : T,
) -> Bool {
  let prepared = self.inner.prepare(t.insert_sql())
  match prepared {
    Some(stmt) => {
      bind_row(stmt, t, @json.to_json(value))
      let executed = stmt.execute()
      stmt.finalize()
      executed
    }
    None => false
  }
}

///|
/// Rows matching a raw WHERE clause with bound arguments, decoded into
/// models. Rows that fail to decode are skipped.
pub fn[T : FromJson] Database::query(
  self : Database,
  t : Table,
  where_clause : String,
  args : Array[@sqlite.SqlValue],
) -> Array[T] {
  let results = []
  let prepared = self.inner.prepare(t.select_sql(where_clause))
  match prepared {
    Some(stmt) => {
      stmt.bind_all(args) |> ignore
      for row in stmt.iter() {
        match decode_row(t, row) {
          Some(value) => results.push(value)
          None => ()
        }
      }
      stmt.finalize()
    }
    None => ()
  }
  results
}

///|
/// All rows of the table, decoded into models.
pub fn[T : FromJson] Database::all(self : Database, t : Table) -> Array[T] {
  self.query(t, "1=1", [])
}

///|
/// The first row whose primary key equals `id`, or None.
pub fn[T : FromJson] Database::find(self : Database, t : Table, id : Int) -> T? {
  match primary_column(t) {
    Some(pk) => {
      let rows : Array[T] = self.query(t, quote_ident(pk.name) + " = ?", [
        @sqlite.Int(id),
      ])
      rows.get(0)
    }
    None => None
  }
}

///|
/// Number of rows in the table.
pub fn Database::count(self : Database, t : Table) -> Int {
  let mut n = 0
  let queried = self.inner.query("SELECT COUNT(*) FROM " + quote_ident(t.name))
  match queried {
    Some(stmt) => {
      for row in stmt.iter() {
        n = row.column_int(0)
      }
      stmt.finalize()
    }
    None => ()
  }
  n
}
