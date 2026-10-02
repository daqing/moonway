///|
/// SQLite storage types understood by moonway.
pub(all) enum ColumnType {
  IntT
  RealT
  TextT
  BoolT
} derive(Eq, Debug)

///|
pub extend ColumnType with Eq::{equal, not_equal}

///|
pub extend ColumnType with @debug.Debug::{to_repr}

///|
fn ColumnType::sql(self : ColumnType) -> String {
  match self {
    IntT => "INTEGER"
    RealT => "REAL"
    TextT => "TEXT"
    BoolT => "INTEGER"
  }
}

///|
pub(all) struct Column {
  name : String
  col_type : ColumnType
  primary : Bool
}

///|
pub(all) struct Table {
  name : String
  columns : Array[Column]
}

///|
/// Declare a table. This description is the source of truth for migrations
/// and the admin UI. Row values flow through the builtin `derive(ToJson,
/// FromJson)` — struct field names are the keys, column types drive the
/// storage conversion.
pub fn table(name : String, columns : Array[Column]) -> Table {
  { name, columns, }
}

///|
pub fn column(
  name : String,
  col_type : ColumnType,
  primary? : Bool = false,
) -> Column {
  { name, col_type, primary, }
}

///|
/// CREATE TABLE IF NOT EXISTS statement for this table.
pub fn Table::create_sql(self : Table) -> String {
  let mut defs = ""
  for i, col in self.columns {
    if i > 0 {
      defs = defs + ", "
    }
    defs = defs + quote_ident(col.name) + " " + col.col_type.sql()
    if col.primary {
      defs = defs + " PRIMARY KEY"
    }
  }
  "CREATE TABLE IF NOT EXISTS " + quote_ident(self.name) + " (" + defs + ")"
}

///|
fn quote_ident(name : String) -> String {
  "\"" + name + "\""
}
