///|
pub struct Database {
  inner : @sqlite.Database
}

///|
/// Open (creating if needed) a SQLite database file. Returns None when the
/// file cannot be opened.
pub fn open(path : String) -> Database? {
  match @sqlite.Database::open(path) {
    Some(inner) => Some({ inner, })
    None => None
  }
}

///|
pub fn Database::close(self : Database) -> Unit {
  self.inner.close()
}

///|
/// Execute a statement that returns no rows. Returns false on failure.
pub fn Database::exec(self : Database, sql : String) -> Bool {
  self.inner.exec(sql)
}

///|
/// Number of rows changed by the most recent statement.
pub fn Database::changes(self : Database) -> Int {
  self.inner.changes()
}

///|
/// Rowid of the most recent successful insert.
pub fn Database::last_insert_rowid(self : Database) -> Int64 {
  self.inner.last_insert_rowid()
}
