///|
pub fn update(table_name : String) -> Builder {
  let builder = Builder::base(StatementKind::Update)
  builder.table_name = table_name
  builder
}

///|
pub fn update_table(table : TableRef) -> Builder {
  update(table.name.to_string())
}

///|
pub fn Builder::set(self : Builder, values : H) -> Builder {
  self.vals = values
  self
}

///|
fn build_update(builder : Builder, state : BuildState) -> String raise SqlError {
  if builder.vals.length() == 0 {
    raise SqlError::NoValuesToUpdate
  }
  let mut sql = write_with_clause(builder, "", state)
  sql = sql + "UPDATE " + builder.table_name + " SET "
  let clauses : Array[String] = []
  for column in sorted_map_keys(builder.vals) {
    match builder.vals.get(column) {
      Some(value) =>
        clauses.push(column + " = " + render_value(state, column, value))
      None => ()
    }
  }
  sql = sql + clauses.join(", ")
  if builder.update_from.length() > 0 {
    sql = sql + " FROM " + builder.update_from.join(", ")
  }
  let where_clause = compile_cond(builder.cond, state)
  if where_clause != "" {
    sql = sql + " WHERE " + where_clause
  }
  write_returning_clause(builder, sql, false)
}
