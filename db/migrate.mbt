///|
pub(all) struct Migration {
  version : Int
  name : String
  statements : Array[String]
}

///|
/// Declare a forward-only migration: its version, a human-readable name and
/// the SQL statements to apply, in order.
pub fn migration(
  version : Int,
  name : String,
  statements : Array[String],
) -> Migration {
  { version, name, statements, }
}

///|
let migrations_table = "moonway_migrations"

///|
/// Apply pending migrations in ascending version order. Already-applied
/// versions (recorded in the moonway_migrations table) are skipped; the
/// runner stops at the first failing statement and returns false.
pub fn Database::migrate(
  self : Database,
  migrations : Array[Migration],
) -> Bool {
  if !self.exec(
      "CREATE TABLE IF NOT EXISTS \"\{migrations_table}\" (\"version\" INTEGER PRIMARY KEY, \"name\" TEXT)",
    ) {
    return false
  }
  let pending = sorted_pending(migrations, self.applied_versions())
  for m in pending {
    for statement in m.statements {
      if !self.exec(statement) {
        return false
      }
    }
    if !self.record_applied(m) {
      return false
    }
  }
  true
}

///|
/// Versions recorded as applied, ascending.
fn Database::applied_versions(self : Database) -> Array[Int] {
  let versions = []
  let queried = self.inner.query(
    "SELECT \"version\" FROM \"\{migrations_table}\" ORDER BY \"version\"",
  )
  match queried {
    Some(stmt) => {
      for row in stmt.iter() {
        versions.push(row.column_int(0))
      }
      stmt.finalize()
    }
    None => ()
  }
  versions
}

///|
/// Migrations not yet applied, ascending by version.
fn sorted_pending(
  migrations : Array[Migration],
  applied : Array[Int],
) -> Array[Migration] {
  let pending = []
  for m in migrations {
    if !applied.contains(m.version) {
      pending.push(m)
    }
  }
  insertion_sort_by_version(pending)
  pending
}

///|
fn insertion_sort_by_version(migrations : Array[Migration]) -> Unit {
  for i in 1..<migrations.length() {
    let m = migrations[i]
    let mut j = i - 1
    while j >= 0 && migrations[j].version > m.version {
      migrations[j + 1] = migrations[j]
      j = j - 1
    }
    migrations[j + 1] = m
  }
}

///|
fn Database::record_applied(self : Database, m : Migration) -> Bool {
  let prepared = self.inner.prepare(
    "INSERT INTO \"\{migrations_table}\" (\"version\", \"name\") VALUES (?, ?)",
  )
  match prepared {
    Some(stmt) => {
      stmt.bind_all([@sqlite.Int(m.version), @sqlite.Text(encode_utf8(m.name))])
      |> ignore
      let executed = stmt.execute()
      stmt.finalize()
      executed
    }
    None => false
  }
}
