///|
pub(all) enum Cond {
  Empty
  Condition(String, String, Expr)
  Compare(Expr, String, Expr)
  And(Array[Cond])
  Or(Array[Cond])
  FlatAnd(Array[Cond])
  Not(Cond)
  In(Expr, Array[Expr], Bool)
  Between(Expr, Expr, Expr, Bool)
  Null(Expr, Bool)
  Exists(Builder, Bool)
  Raw(String, NamedArgs)
}

///|
pub fn empty_cond() -> Cond {
  Cond::Empty
}

///|
pub fn condition(key : String, operator : String, value : Expr) -> Cond {
  Cond::Condition(key, operator, value)
}

///|
pub fn compare(left : Expr, operator : String, right : Expr) -> Cond {
  Cond::Compare(left, operator, right)
}

///|
pub fn eq(key : String, value : Expr) -> Cond {
  condition(key, "=", value)
}

///|
pub fn not_eq(key : String, value : Expr) -> Cond {
  condition(key, "<>", value)
}

///|
pub fn gt(key : String, value : Expr) -> Cond {
  condition(key, ">", value)
}

///|
pub fn gte(key : String, value : Expr) -> Cond {
  condition(key, ">=", value)
}

///|
pub fn lt(key : String, value : Expr) -> Cond {
  condition(key, "<", value)
}

///|
pub fn lte(key : String, value : Expr) -> Cond {
  condition(key, "<=", value)
}

///|
pub fn like(key : String, value : Expr) -> Cond {
  condition(key, "LIKE", value)
}

///|
pub fn not_like(key : String, value : Expr) -> Cond {
  condition(key, "NOT LIKE", value)
}

///|
pub fn ilike(key : String, value : Expr) -> Cond {
  condition(key, "ILIKE", value)
}

///|
pub fn not_ilike(key : String, value : Expr) -> Cond {
  condition(key, "NOT ILIKE", value)
}

///|
pub fn field_eq(column : ColumnRef, value : Expr) -> Cond {
  compare(column.ref().to_expr(), "=", value)
}

///|
pub fn eq_ref(column : ColumnRef, value : Expr) -> Cond {
  field_eq(column, value)
}

///|
pub fn field_not_eq(column : ColumnRef, value : Expr) -> Cond {
  compare(column.ref().to_expr(), "<>", value)
}

///|
pub fn field_gt(column : ColumnRef, value : Expr) -> Cond {
  compare(column.ref().to_expr(), ">", value)
}

///|
pub fn field_gte(column : ColumnRef, value : Expr) -> Cond {
  compare(column.ref().to_expr(), ">=", value)
}

///|
pub fn field_lt(column : ColumnRef, value : Expr) -> Cond {
  compare(column.ref().to_expr(), "<", value)
}

///|
pub fn field_lte(column : ColumnRef, value : Expr) -> Cond {
  compare(column.ref().to_expr(), "<=", value)
}

///|
pub fn field_like(column : ColumnRef, value : Expr) -> Cond {
  compare(column.ref().to_expr(), "LIKE", value)
}

///|
pub fn field_ilike(column : ColumnRef, value : Expr) -> Cond {
  compare(column.ref().to_expr(), "ILIKE", value)
}

///|
pub fn h_cond(values : H) -> Cond {
  let conditions : Array[Cond] = []
  for key in sorted_map_keys(values) {
    match values.get(key) {
      Some(value) => conditions.push(eq(key, value))
      None => ()
    }
  }
  join_conditions(conditions, false)
}

///|
pub fn match_fields(table : TableRef, values : H) -> Cond {
  let conditions : Array[Cond] = []
  for key in sorted_map_keys(values) {
    match values.get(key) {
      Some(value) => conditions.push(field_eq(table.field(key), value))
      None => ()
    }
  }
  all_of(conditions)
}

///|
pub fn h_cond_ref(table : TableRef, values : H) -> Cond {
  match_fields(table, values)
}

///|
pub fn in_cond(column : Expr, values : Array[Expr]) -> Cond {
  Cond::In(column, values, false)
}

///|
pub fn not_in_cond(column : Expr, values : Array[Expr]) -> Cond {
  Cond::In(column, values, true)
}

///|
pub fn all_of(conditions : Array[Cond]) -> Cond {
  Cond::And(conditions)
}

///|
pub fn any_of(conditions : Array[Cond]) -> Cond {
  Cond::Or(conditions)
}

///|
pub fn not(condition : Cond) -> Cond {
  Cond::Not(condition)
}

///|
pub fn is_null(column : Expr) -> Cond {
  Cond::Null(column, false)
}

///|
pub fn is_not_null(column : Expr) -> Cond {
  Cond::Null(column, true)
}

///|
pub fn between(column : Expr, lower : Expr, upper : Expr) -> Cond {
  Cond::Between(column, lower, upper, false)
}

///|
pub fn not_between(column : Expr, lower : Expr, upper : Expr) -> Cond {
  Cond::Between(column, lower, upper, true)
}

///|
pub fn exists_query(query : Builder) -> Cond {
  Cond::Exists(query, false)
}

///|
pub fn not_exists_query(query : Builder) -> Cond {
  Cond::Exists(query, true)
}

///|
pub fn raw_condition(sql : String, args : NamedArgs) -> Cond {
  Cond::Raw(sql, args)
}

///|
pub fn array_contains(left : Expr, right : Expr) -> Cond {
  compare(left, "@>", right)
}

///|
pub fn array_contained_by(left : Expr, right : Expr) -> Cond {
  compare(left, "<@", right)
}

///|
pub fn array_overlap(left : Expr, right : Expr) -> Cond {
  compare(left, "&&", right)
}

///|
pub fn json_get(left : Expr, key : Expr) -> Expr {
  op(left, "->", key)
}

///|
pub fn json_get_text(left : Expr, key : Expr) -> Expr {
  op(left, "->>", key)
}

///|
pub fn json_path(left : Expr, path : Array[String]) -> Expr {
  op(left, "#>", cast(array(path.map(val)), "text[]"))
}

///|
pub fn json_path_text(left : Expr, path : Array[String]) -> Expr {
  op(left, "#>>", cast(array(path.map(val)), "text[]"))
}

///|
pub fn json_contains(left : Expr, right : Expr) -> Cond {
  compare(left, "@>", right)
}

///|
pub fn json_contained_by(left : Expr, right : Expr) -> Cond {
  compare(left, "<@", right)
}

///|
pub fn json_has_key(left : Expr, key : String) -> Cond {
  compare(left, "?", val(key))
}

///|
pub fn json_has_any_keys(left : Expr, keys : Array[String]) -> Cond {
  compare(left, "?|", array(keys.map(val)))
}

///|
pub fn json_has_all_keys(left : Expr, keys : Array[String]) -> Cond {
  compare(left, "?&", array(keys.map(val)))
}

///|
pub fn Cond::to_sql(self : Cond) -> (String, NamedArgs) raise SqlError {
  let state = BuildState::new()
  let sql = compile_cond(self, state)
  (sql, state.args)
}

///|
fn compile_cond(condition : Cond, state : BuildState) -> String raise SqlError {
  match condition {
    Empty => ""
    Condition(key, operator, value) => {
      if is_null_expr(value) {
        return match operator.to_upper() {
          "=" | "IS" => key + " IS NULL"
          "!=" | "<>" | "IS NOT" => key + " IS NOT NULL"
          _ => key + " " + operator + " NULL"
        }
      }
      key + " " + operator + " " + render_value(state, key, value)
    }
    Compare(left, operator, right) => {
      if is_null_expr(right) {
        let rendered = render_value(state, "left", left)
        return match operator.to_upper() {
          "=" | "IS" => rendered + " IS NULL"
          "!=" | "<>" | "IS NOT" => rendered + " IS NOT NULL"
          _ => rendered + " " + operator + " NULL"
        }
      }
      let left_sql = render_value(state, "left", left)
      let right_sql = render_value(state, "right", right)
      if left_sql == "" || right_sql == "" {
        ""
      } else {
        left_sql + " " + operator + " " + right_sql
      }
    }
    And(conditions) => join_cond(conditions, " AND ", true, state)
    Or(conditions) => join_cond(conditions, " OR ", true, state)
    FlatAnd(conditions) => join_cond(conditions, " AND ", false, state)
    Not(inner) => {
      let clause = compile_cond(inner, state)
      if clause == "" {
        ""
      } else {
        "NOT (" + clause + ")"
      }
    }
    In(column, values, negated) => {
      if values.length() == 0 {
        return if negated { "TRUE" } else { "FALSE" }
      }
      let hint = expr_hint(column)
      let placeholders : Array[String] = []
      for value in values {
        placeholders.push(render_value(state, hint, value))
      }
      render_value(state, "column", column) +
      (if negated { " NOT IN (" } else { " IN (" }) +
      placeholders.join(", ") +
      ")"
    }
    Between(column, lower, upper, negated) => {
      let hint = expr_hint(column)
      render_value(state, "column", column) +
      (if negated { " NOT BETWEEN " } else { " BETWEEN " }) +
      render_value(state, hint + "_from", lower) +
      " AND " +
      render_value(state, hint + "_to", upper)
    }
    Null(column, negated) =>
      render_value(state, "column", column) +
      (if negated { " IS NOT NULL" } else { " IS NULL" })
    Exists(query, negated) => {
      let compiled = query.to_sql()
      let query_sql = "(" + state.merge_expr(compiled.0, compiled.1) + ")"
      (if negated { "NOT EXISTS " } else { "EXISTS " }) + query_sql
    }
    Raw(sql, args) => state.merge_expr(sql, args)
  }
}

///|
fn join_cond(
  conditions : Array[Cond],
  separator : String,
  wrap : Bool,
  state : BuildState,
) -> String raise SqlError {
  let clauses : Array[String] = []
  for condition in conditions {
    let clause = compile_cond(condition, state)
    if clause != "" {
      clauses.push(clause)
    }
  }
  if wrap && clauses.length() > 1 {
    "(" + clauses.join(separator) + ")"
  } else {
    clauses.join(separator)
  }
}

///|
fn join_conditions(conditions : Array[Cond], wrap : Bool) -> Cond {
  if conditions.length() == 0 {
    Cond::Empty
  } else if wrap {
    Cond::And(conditions)
  } else {
    Cond::FlatAnd(conditions)
  }
}

///|
fn expr_hint(value : Expr) -> String {
  match value {
    Static(name) | Raw(name, _) => name
    _ => "value"
  }
}

///|
fn is_null_expr(value : Expr) -> Bool {
  value is Literal(Value::Null)
}
