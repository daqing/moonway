///|
pub fn select(fields : String) -> Builder {
  let parts = if fields.trim().to_owned() == "" ||
    fields.trim().to_owned() == "*" {
    ["*"]
  } else {
    fields.split(",").map(part => part.to_owned()).to_array()
  }
  select_columns(parts)
}

///|
pub fn select_columns(fields : Array[String]) -> Builder {
  let builder = Builder::base(StatementKind::Select)
  let normalized = normalize_fields(fields)
  builder.fields = if normalized.length() == 0 { ["*"] } else { normalized }
  builder
}

///|
pub fn select_fields(columns : Array[ColumnRef]) -> Builder {
  select_columns(columns.map(column => column.to_string()))
}

///|
pub fn select_refs(columns : Array[ColumnRef]) -> Builder {
  select_fields(columns)
}

///|
pub fn Builder::columns(self : Builder, fields : Array[String]) -> Builder {
  self.fields.append(normalize_fields(fields))
  self
}

///|
pub fn Builder::fields(self : Builder, columns : Array[ColumnRef]) -> Builder {
  for column in columns {
    self.fields.push(column.to_string())
  }
  self
}

///|
pub fn Builder::from(self : Builder, table_name : String) -> Builder {
  self.from_expr = None
  self.table_name = table_name
  self
}

///|
pub fn Builder::from_table(self : Builder, table : TableRef) -> Builder {
  self.from_expr(table.to_expr())
}

///|
pub fn Builder::from_expr(self : Builder, expression : Expr) -> Builder {
  self.table_name = ""
  self.from_expr = Some(expression)
  self
}

///|
pub fn Builder::from_sub_query(
  self : Builder,
  query : Builder,
  alias : String,
) -> Builder {
  let expression = if alias.trim().to_owned() == "" {
    sub_query(query)
  } else {
    Expr::Wrapper("", sub_query(query), " AS " + alias.trim().to_owned())
  }
  self.from_expr(expression)
}

///|
fn build_select(builder : Builder, state : BuildState) -> String raise SqlError {
  let mut sql = build_select_core(builder, state)
  for operation in builder.set_ops {
    let compiled = operation.query.to_sql()
    sql = sql +
      " " +
      operation.kind +
      " (" +
      state.merge_expr(compiled.0, compiled.1) +
      ")"
  }
  sql = write_order_limit_offset(builder, sql)
  match lock_sql(builder.lock_clause) {
    "" => ()
    clause => sql = sql + " " + clause
  }
  sql
}

///|
fn build_select_core(
  builder : Builder,
  state : BuildState,
) -> String raise SqlError {
  let fields = if builder.fields.length() == 0 { ["*"] } else { builder.fields }
  let mut sql = write_with_clause(builder, "", state)
  sql = sql + "SELECT "
  if builder.distinct_on.length() > 0 {
    sql = sql + "DISTINCT ON (" + builder.distinct_on.join(", ") + ") "
  } else if builder.distinct {
    sql = sql + "DISTINCT "
  }
  sql = sql + fields.join(", ")
  let from_sql = match builder.from_expr {
    Some(expression) => render_value(state, "from", expression)
    None => builder.table_name
  }
  if from_sql != "" {
    sql = sql + " FROM " + from_sql
  }
  for join in builder.joins {
    let join_sql = build_join(join, state)
    if join_sql != "" {
      sql = sql + " " + join_sql
    }
  }
  let where_clause = compile_cond(builder.cond, state)
  if where_clause != "" {
    sql = sql + " WHERE " + where_clause
  }
  if builder.group_bys.length() > 0 {
    sql = sql + " GROUP BY " + builder.group_bys.join(", ")
  }
  let having = compile_cond(builder.having, state)
  if having != "" {
    sql = sql + " HAVING " + having
  }
  if builder.windows.length() > 0 {
    sql = sql + " WINDOW " + builder.windows.join(", ")
  }
  sql
}

///|
fn build_join(join : JoinClause, state : BuildState) -> String raise SqlError {
  let mut source = match join.expr {
    Some(expression) => render_value(state, "join", expression)
    None => join.table_name
  }
  if source == "" {
    return ""
  }
  if join.lateral {
    source = "LATERAL " + source
  }
  if join.kind == "CROSS JOIN" {
    return join.kind + " " + source
  }
  let on = compile_cond(join.on, state)
  join.kind + " " + source + (if on == "" { "" } else { " ON " + on })
}

///|
fn write_order_limit_offset(builder : Builder, initial : String) -> String {
  let mut sql = initial
  if builder.order_bys.length() > 0 {
    sql = sql + " ORDER BY " + builder.order_bys.join(", ")
  }
  if builder.limit > -1 {
    sql = sql + " LIMIT " + builder.limit.to_string()
  }
  if builder.offset > -1 {
    sql = sql + " OFFSET " + builder.offset.to_string()
  }
  sql
}

///|
fn lock_sql(lock : LockClause?) -> String {
  match lock {
    None => ""
    Some(Raw(clause)) => clause
    Some(For(strength, option)) =>
      "FOR " + strength + (if option == "" { "" } else { " " + option })
  }
}

///|
fn write_with_clause(
  builder : Builder,
  initial : String,
  state : BuildState,
) -> String raise SqlError {
  if builder.with_clauses.length() == 0 {
    return initial
  }
  let parts : Array[String] = []
  let mut recursive = false
  for cte in builder.with_clauses {
    if cte.name == "" {
      continue
    }
    recursive = recursive || cte.recursive
    let compiled = cte.query.to_sql()
    parts.push(
      cte.name + " AS (" + state.merge_expr(compiled.0, compiled.1) + ")",
    )
  }
  if parts.length() == 0 {
    initial
  } else {
    initial +
    "WITH " +
    (if recursive { "RECURSIVE " } else { "" }) +
    parts.join(", ") +
    " "
  }
}
