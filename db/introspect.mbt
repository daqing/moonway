///|
/// Schema introspection for tools that work with arbitrary databases (the
/// `moonway console`): tables and columns are read from SQLite's own
/// catalog, so no compiled-in model types are required.

///|
/// Names of user tables (sqlite_master), excluding internal `sqlite_%`
/// tables, ordered by name.
pub fn Database::list_tables(self : Database) -> Array[String] {
  let names = []
  let prepared = self.inner.prepare(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite\\_%' ESCAPE '\\' ORDER BY name",
  )
  match prepared {
    Some(stmt) => {
      for row in stmt.iter() {
        names.push(bytes_to_string(row.column_text(0)))
      }
      stmt.finalize()
    }
    None => ()
  }
  names
}

///|
/// Rebuild a Table descriptor from SQLite's catalog (PRAGMA table_info).
/// Declared types map by keyword: *BOOL* → BoolT, *INT* → IntT,
/// *REAL*/*FLOA*/*DOUB* → RealT, everything else → TextT. Returns None for
/// unknown tables.
pub fn Database::table_schema(self : Database, name : String) -> Table? {
  let columns : Array[Column] = []
  let prepared = self.inner.prepare(
    "PRAGMA table_info(" + quote_ident(name) + ")",
  )
  match prepared {
    Some(stmt) => {
      for row in stmt.iter() {
        let col_name = bytes_to_string(row.column_text(1))
        let declared = bytes_to_string(row.column_text(2))
        let pk = row.column_int(5)
        columns.push({
          name: col_name,
          col_type: declared_to_type(declared),
          primary: pk > 0,
        })
      }
      stmt.finalize()
    }
    None => ()
  }
  if columns.length() == 0 {
    None
  } else {
    Some({ name, columns, })
  }
}

///|
fn declared_to_type(declared : String) -> ColumnType {
  let d = declared.to_lower()
  if d.contains("bool") {
    BoolT
  } else if d.contains("int") {
    IntT
  } else if d.contains("real") || d.contains("floa") || d.contains("doub") {
    RealT
  } else {
    TextT
  }
}
