///|
pub(all) enum Driver {
  Postgres
  MySQL
  SQLite
} derive(Debug, Eq)

///|
pub(all) suberror RepoError {
  EmptyDsn
  CannotInferDriver(String)
  UnsupportedDriver(String)
  UnsupportedFeature(String)
  MissingNamedArg(String)
  NotSetup
  OpenFailed(String)
  PrepareFailed(String)
  ExecuteFailed(String)
  QueryFailed(String)
  DecodeFailed(String)
  CountNotMatch
  MissingDestination(String)
  RelationNotFound(String)
  InvalidRecord(String)
} derive(Debug)

///|
pub fn normalize_driver(name : String) -> Driver? raise RepoError {
  match name.trim().to_owned().to_lower() {
    "" | "auto" => None
    "postgres" | "postgresql" | "pg" | "pgx" => Some(Driver::Postgres)
    "mysql" | "mysql8" | "mysql8.4" => Some(Driver::MySQL)
    "sqlite" => Some(Driver::SQLite)
    other => raise RepoError::UnsupportedDriver(other)
  }
}

///|
pub fn detect_driver_from_dsn(dsn : String) -> Driver? {
  let normalized = dsn.trim().to_owned().to_lower()
  if normalized.has_prefix("postgres://") ||
    normalized.has_prefix("postgresql://") {
    Some(Driver::Postgres)
  } else if normalized.has_prefix("mysql://") ||
    normalized.contains("@tcp(") ||
    normalized.contains("@unix(") ||
    normalized.contains(")/") {
    Some(Driver::MySQL)
  } else if normalized.has_prefix("sqlite://") ||
    normalized.has_prefix("file:") ||
    normalized == ":memory:" ||
    normalized.has_suffix(".db") ||
    normalized.has_suffix(".sqlite") {
    Some(Driver::SQLite)
  } else if normalized.contains("host=") ||
    normalized.contains("user=") ||
    normalized.contains("dbname=") {
    Some(Driver::Postgres)
  } else {
    None
  }
}

///|
pub fn resolve_driver(
  driver_name : String,
  dsn : String,
) -> (Driver, String) raise RepoError {
  let normalized_dsn = dsn.trim().to_owned()
  if normalized_dsn == "" {
    raise RepoError::EmptyDsn
  }
  let driver = match normalize_driver(driver_name) {
    Some(driver) => driver
    None =>
      match detect_driver_from_dsn(normalized_dsn) {
        Some(driver) => driver
        None => raise RepoError::CannotInferDriver(normalized_dsn)
      }
  }
  (driver, normalize_dsn(driver, normalized_dsn))
}

///|
pub fn normalize_dsn(driver : Driver, dsn : String) -> String {
  let normalized = dsn.trim().to_owned()
  match driver {
    SQLite =>
      if normalized.to_lower().has_prefix("sqlite://") {
        normalized[9:].to_owned()
      } else {
        normalized
      }
    MySQL => normalize_mysql_dsn(normalized)
    Postgres => normalized
  }
}

///|
fn normalize_mysql_dsn(dsn : String) -> String {
  let mut normalized = dsn.trim().to_owned()
  if normalized.to_lower().has_prefix("mysql://") {
    let rest = normalized[8:].to_owned()
    let at_parts = rest.split("@").to_array()
    if at_parts.length() >= 2 {
      let credentials = at_parts[0].to_owned()
      let host_and_database = at_parts[at_parts.length() - 1].to_owned()
      let path_parts = host_and_database.split("/").to_array()
      let host = if path_parts[0].to_owned() == "" {
        "127.0.0.1:3306"
      } else {
        path_parts[0].to_owned()
      }
      let database = if path_parts.length() > 1 {
        path_parts[1:].iter().map(part => part.to_owned()).join("/")
      } else {
        ""
      }
      normalized = credentials + "@tcp(" + host + ")/" + database
    }
  }
  if normalized.to_lower().contains("parsetime=") {
    normalized
  } else if normalized.contains("?") {
    normalized + "&parseTime=true"
  } else {
    normalized + "?parseTime=true"
  }
}

///|
pub fn Driver::rebind(self : Driver, query : String) -> String {
  if self != Driver::Postgres {
    return query
  }
  let mut output = ""
  let mut position = 0
  let mut rest = query
  while true {
    match rest.find("?") {
      Some(index) => {
        position += 1
        output = output + rest[:index].to_owned() + "$" + position.to_string()
        rest = rest[index + 1:].to_owned()
      }
      None => {
        output = output + rest
        break
      }
    }
  }
  output
}
