///|
pub fn insert(values : H) -> Builder {
  let builder = Builder::base(StatementKind::Insert)
  builder.vals = values
  builder
}

///|
pub fn insert_rows(rows : Array[H]) -> Builder {
  let builder = Builder::base(StatementKind::Insert)
  builder.rows = rows
  builder
}

///|
pub fn Builder::into(self : Builder, table_name : String) -> Builder {
  self.table_name = table_name
  self
}

///|
pub fn Builder::into_table(self : Builder, table : TableRef) -> Builder {
  self.table_name = table.name.to_string()
  self
}

///|
fn build_insert(builder : Builder, state : BuildState) -> String raise SqlError {
  if builder.insert_query is Some(_) {
    return build_insert_select(builder, state)
  }
  let rows = if builder.rows.length() == 0 {
    [builder.vals]
  } else {
    builder.rows
  }
  if rows.length() == 0 || rows[0].length() == 0 {
    raise SqlError::NoValuesToInsert
  }
  let columns = sorted_map_keys(rows[0])
  for i, row in rows {
    if row.length() != columns.length() {
      raise SqlError::InsertColumnMismatch(row=i, column="")
    }
    for column in columns {
      if !row.contains(column) {
        raise SqlError::InsertColumnMismatch(row=i, column~)
      }
    }
  }
  let mut sql = write_with_clause(builder, "", state)
  sql = sql +
    "INSERT INTO " +
    builder.table_name +
    " (" +
    columns.join(", ") +
    ") VALUES "
  let row_clauses : Array[String] = []
  for row in rows {
    let values : Array[String] = []
    for column in columns {
      match row.get(column) {
        Some(value) => values.push(render_value(state, column, value))
        None => ()
      }
    }
    row_clauses.push("(" + values.join(", ") + ")")
  }
  sql = sql + row_clauses.join(", ")
  sql = write_conflict_clause(builder, sql, state)
  write_returning_clause(builder, sql, true)
}

///|
fn build_insert_select(
  builder : Builder,
  state : BuildState,
) -> String raise SqlError {
  guard builder.insert_query is Some(query) else {
    raise SqlError::NoValuesToInsert
  }
  if builder.insert_columns.length() == 0 {
    raise SqlError::NoInsertColumns
  }
  let compiled = query.to_sql()
  let mut sql = write_with_clause(builder, "", state)
  sql = sql +
    "INSERT INTO " +
    builder.table_name +
    " (" +
    builder.insert_columns.join(", ") +
    ") " +
    state.merge_expr(compiled.0, compiled.1)
  sql = write_conflict_clause(builder, sql, state)
  write_returning_clause(builder, sql, true)
}

///|
fn write_conflict_clause(
  builder : Builder,
  initial : String,
  state : BuildState,
) -> String raise SqlError {
  guard builder.conflict is Some(conflict) else { return initial }
  let mut sql = initial + " ON CONFLICT"
  if conflict.constraint_name != "" {
    sql = sql + " ON CONSTRAINT " + conflict.constraint_name
  } else if conflict.target.length() > 0 {
    sql = sql + " (" + conflict.target.join(", ") + ")"
  }
  if conflict.do_nothing {
    return sql + " DO NOTHING"
  }
  if conflict.set.length() == 0 {
    raise SqlError::NoConflictValues
  }
  let clauses : Array[String] = []
  for column in sorted_map_keys(conflict.set) {
    match conflict.set.get(column) {
      Some(value) =>
        clauses.push(column + " = " + render_value(state, column, value))
      None => ()
    }
  }
  sql + " DO UPDATE SET " + clauses.join(", ")
}

///|
fn write_returning_clause(
  builder : Builder,
  initial : String,
  insert_default : Bool,
) -> String {
  let fields = if insert_default && builder.returning.length() == 0 {
    ["*"]
  } else {
    builder.returning
  }
  if fields.length() == 0 {
    initial
  } else {
    initial + " RETURNING " + fields.join(", ")
  }
}
