///|
/// Open the SQLite database for your app (see the README full-stack
/// example). A failed open is fatal at startup.
pub fn sqlite(path : String) -> @db.Database {
  match @db.open(path) {
    Some(db) => db
    None => abort("moonway: cannot open database at \{path}")
  }
}
