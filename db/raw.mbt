///|
/// Raw row access for tools that work with arbitrary tables (the admin
/// dashboard): rows are plain JSON objects keyed by column name.
/// The `select_raw` where clause is spliced into SQL verbatim — callers
/// must never pass user input unescaped.

///|
fn row_fields(t : Table, row : @sqlite.Statement) -> Map[String, Json] {
  let fields : Map[String, Json] = Map([])
  for i, col in t.columns {
    fields[col.name] = sql_to_json(row.column(i), col.col_type)
  }
  fields
}

///|
/// Select rows as raw JSON objects with LIMIT/OFFSET pagination. The where
/// clause is appended verbatim after WHERE (pass "1=1" for no filter).
pub fn Database::select_raw(
  self : Database,
  t : Table,
  where_clause : String,
  args : Array[@sqlite.SqlValue],
  limit? : Int = 50,
  offset? : Int = 0,
) -> Array[Json] {
  let results = []
  let sql = "SELECT " +
    column_list(t) +
    " FROM " +
    quote_ident(t.name) +
    " WHERE " +
    where_clause +
    " LIMIT \{limit} OFFSET \{offset}"
  let prepared = self.inner.prepare(sql)
  match prepared {
    Some(stmt) => {
      stmt.bind_all(args) |> ignore
      for row in stmt.iter() {
        results.push(Json::object(row_fields(t, row)))
      }
      stmt.finalize()
    }
    None => ()
  }
  results
}

///|
/// The first row whose primary key equals `id`, as a raw JSON object.
pub fn Database::find_raw(self : Database, t : Table, id : Int) -> Json? {
  match primary_column(t) {
    Some(pk) => {
      let rows = self.select_raw(
        t,
        quote_ident(pk.name) + " = ?",
        [@sqlite.Int(id)],
        limit=1,
      )
      rows.get(0)
    }
    None => None
  }
}

///|
/// Insert a raw row (column name → JSON value). Missing columns bind NULL.
pub fn Database::insert_raw(
  self : Database,
  t : Table,
  row : Map[String, Json],
) -> Bool {
  let prepared = self.inner.prepare(t.insert_sql())
  match prepared {
    Some(stmt) => {
      let values : Array[@sqlite.SqlValue] = []
      for col in t.columns {
        let value = match row.get(col.name) {
          Some(field_json) => json_to_sql(field_json, col.col_type)
          None => None
        }
        values.push(
          match value {
            Some(sql_value) => sql_value
            None => @sqlite.Null
          },
        )
      }
      stmt.bind_all(values) |> ignore
      let executed = stmt.execute()
      stmt.finalize()
      executed
    }
    None => false
  }
}

///|
/// Update the row with primary key `id`, setting every non-primary column
/// from `row` (missing columns become NULL). Returns false on failure.
pub fn Database::update_raw(
  self : Database,
  t : Table,
  id : Int,
  row : Map[String, Json],
) -> Bool {
  match primary_column(t) {
    Some(pk) => {
      let mut sets = ""
      let values : Array[@sqlite.SqlValue] = []
      for col in t.columns {
        if col.primary {
          continue
        }
        if sets != "" {
          sets = sets + ", "
        }
        sets = sets + quote_ident(col.name) + " = ?"
        let value = match row.get(col.name) {
          Some(field_json) => json_to_sql(field_json, col.col_type)
          None => None
        }
        values.push(
          match value {
            Some(sql_value) => sql_value
            None => @sqlite.Null
          },
        )
      }
      values.push(@sqlite.Int(id))
      let sql = "UPDATE " +
        quote_ident(t.name) +
        " SET " +
        sets +
        " WHERE " +
        quote_ident(pk.name) +
        " = ?"
      let prepared = self.inner.prepare(sql)
      match prepared {
        Some(stmt) => {
          stmt.bind_all(values) |> ignore
          let executed = stmt.execute()
          stmt.finalize()
          executed
        }
        None => false
      }
    }
    None => false
  }
}

///|
/// Delete the row with primary key `id`. Returns false on failure.
pub fn Database::delete_raw(self : Database, t : Table, id : Int) -> Bool {
  match primary_column(t) {
    Some(pk) => {
      let prepared = self.inner.prepare(
        "DELETE FROM " +
        quote_ident(t.name) +
        " WHERE " +
        quote_ident(pk.name) +
        " = ?",
      )
      match prepared {
        Some(stmt) => {
          stmt.bind_all([@sqlite.Int(id)]) |> ignore
          let executed = stmt.execute()
          stmt.finalize()
          executed
        }
        None => false
      }
    }
    None => false
  }
}
