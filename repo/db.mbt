///|
pub struct DB {
  priv driver : Driver
  priv conn : @db.Database
}

///|
pub struct Executor {
  priv driver : Driver
  priv conn : @db.Database
}

///|
let current_database : Ref[DB?] = Ref(None)

///|
pub fn new_db(dsn : String) -> DB raise RepoError {
  new_db_with_driver("", dsn)
}

///|
pub fn new_db_with_driver(
  driver_name : String,
  dsn : String,
) -> DB raise RepoError {
  let (driver, normalized_dsn) = resolve_driver(driver_name, dsn)
  if driver != Driver::SQLite {
    raise RepoError::UnsupportedDriver(
      "only SQLite execution is available; use Preview for PostgreSQL/MySQL",
    )
  }
  match @db.open(normalized_dsn) {
    Some(conn) => { driver, conn, }
    None => raise RepoError::OpenFailed(normalized_dsn)
  }
}

///|
pub fn DB::from_database(
  conn : @db.Database,
  driver~ : Driver = Driver::SQLite,
) -> DB {
  { driver, conn, }
}

///|
pub fn DB::driver(self : DB) -> Driver {
  self.driver
}

///|
pub fn DB::raw(self : DB) -> @db.Database {
  self.conn
}

///|
pub fn DB::close(self : DB) -> Unit {
  self.conn.close()
}

///|
pub fn DB::executor(self : DB) -> Executor {
  { driver: self.driver, conn: self.conn, }
}

///|
pub fn setup(dsn : String) -> DB raise RepoError {
  setup_with_driver("", dsn)
}

///|
pub fn setup_with_driver(
  driver_name : String,
  dsn : String,
) -> DB raise RepoError {
  let database = new_db_with_driver(driver_name, dsn)
  if current_database.val is Some(previous) {
    previous.close()
  }
  current_database.val = Some(database)
  database
}

///|
pub fn current_db() -> DB raise RepoError {
  match current_database.val {
    Some(database) => database
    None => raise RepoError::NotSetup
  }
}

///|
pub fn current_db_ok() -> DB? {
  current_database.val
}
