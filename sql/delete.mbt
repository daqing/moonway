///|
pub fn delete() -> Builder {
  Builder::base(StatementKind::Delete)
}

///|
pub fn delete_from(table : TableRef) -> Builder {
  delete().from(table.name.to_string())
}

///|
fn build_delete(builder : Builder, state : BuildState) -> String raise SqlError {
  let mut sql = write_with_clause(builder, "", state)
  sql = sql + "DELETE FROM " + builder.table_name
  if builder.using_tables.length() > 0 {
    sql = sql + " USING " + builder.using_tables.join(", ")
  }
  if builder.native_delete_limit &&
    builder.using_tables.length() == 0 &&
    builder.offset < 0 &&
    (builder.order_bys.length() > 0 || builder.limit > -1) {
    let where_clause = compile_cond(builder.cond, state)
    if where_clause != "" {
      sql = sql + " WHERE " + where_clause
    }
    if builder.order_bys.length() > 0 {
      sql = sql + " ORDER BY " + builder.order_bys.join(", ")
    }
    if builder.limit > -1 {
      sql = sql + " LIMIT " + builder.limit.to_string()
    }
    return write_returning_clause(builder, sql, false)
  }
  if builder.order_bys.length() > 0 || builder.limit > -1 || builder.offset > -1 {
    sql = sql +
      " WHERE " +
      builder.delete_key +
      " IN (SELECT " +
      builder.delete_key +
      " FROM " +
      builder.table_name
    let where_clause = compile_cond(builder.cond, state)
    if where_clause != "" {
      sql = sql + " WHERE " + where_clause
    }
    if builder.order_bys.length() > 0 {
      sql = sql + " ORDER BY " + builder.order_bys.join(", ")
    }
    if builder.limit > -1 {
      sql = sql + " LIMIT " + builder.limit.to_string()
    }
    if builder.offset > -1 {
      sql = sql + " OFFSET " + builder.offset.to_string()
    }
    sql = sql + ")"
    return write_returning_clause(builder, sql, false)
  }
  let where_clause = compile_cond(builder.cond, state)
  if where_clause != "" {
    sql = sql + " WHERE " + where_clause
  }
  write_returning_clause(builder, sql, false)
}
