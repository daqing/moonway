///|
pub(all) enum StatementKind {
  Select
  Insert
  Update
  Delete
} derive(Debug, Eq)

///|
priv enum LockClause {
  Raw(String)
  For(String, String)
}

///|
priv struct ConflictClause {
  target : Array[String]
  constraint_name : String
  do_nothing : Bool
  set : H
}

///|
priv struct CteClause {
  name : String
  query : Builder
  recursive : Bool
}

///|
priv struct JoinClause {
  kind : String
  table_name : String
  expr : Expr?
  lateral : Bool
  on : Cond
}

///|
priv struct SetOperation {
  kind : String
  query : Builder
}

///|
pub struct Builder {
  priv kind : StatementKind
  priv mut table_name : String
  priv mut from_expr : Expr?
  priv mut fields : Array[String]
  priv mut insert_columns : Array[String]
  priv mut insert_query : Builder?
  priv mut cond : Cond
  priv mut vals : H
  priv mut rows : Array[H]
  priv mut order_bys : Array[String]
  priv mut group_bys : Array[String]
  priv mut windows : Array[String]
  priv mut having : Cond
  priv mut joins : Array[JoinClause]
  priv mut set_ops : Array[SetOperation]
  priv mut with_clauses : Array[CteClause]
  priv mut returning : Array[String]
  priv mut update_from : Array[String]
  priv mut using_tables : Array[String]
  priv mut distinct : Bool
  priv mut distinct_on : Array[String]
  priv mut lock_clause : LockClause?
  priv mut conflict : ConflictClause?
  priv mut delete_key : String
  priv mut offset : Int32
  priv mut limit : Int32
  priv mut native_delete_limit : Bool
}

///|
pub(open) trait Stmt {
  fn to_sql(Self) -> (String, NamedArgs) raise SqlError
  fn kind(Self) -> StatementKind
  fn table_name(Self) -> String
  fn insert_values(Self) -> H
  fn insert_rows(Self) -> Array[H]
  fn conflict_target(Self) -> Array[String]
  fn without_locking(Self) -> Self
  fn without_delete_subquery(Self) -> Self
}

///|
fn Builder::base(kind : StatementKind) -> Builder {
  {
    kind,
    table_name: "",
    from_expr: None,
    fields: [],
    insert_columns: [],
    insert_query: None,
    cond: Cond::Empty,
    vals: Map([]),
    rows: [],
    order_bys: [],
    group_bys: [],
    windows: [],
    having: Cond::Empty,
    joins: [],
    set_ops: [],
    with_clauses: [],
    returning: [],
    update_from: [],
    using_tables: [],
    distinct: false,
    distinct_on: [],
    lock_clause: None,
    conflict: None,
    delete_key: "id",
    offset: -1,
    limit: -1,
    native_delete_limit: false,
  }
}

///|
fn Builder::copy(self : Builder) -> Builder {
  {
    kind: self.kind,
    table_name: self.table_name,
    from_expr: self.from_expr,
    fields: self.fields.copy(),
    insert_columns: self.insert_columns.copy(),
    insert_query: self.insert_query,
    cond: self.cond,
    vals: self.vals,
    rows: self.rows.copy(),
    order_bys: self.order_bys.copy(),
    group_bys: self.group_bys.copy(),
    windows: self.windows.copy(),
    having: self.having,
    joins: self.joins.copy(),
    set_ops: self.set_ops.copy(),
    with_clauses: self.with_clauses.copy(),
    returning: self.returning.copy(),
    update_from: self.update_from.copy(),
    using_tables: self.using_tables.copy(),
    distinct: self.distinct,
    distinct_on: self.distinct_on.copy(),
    lock_clause: self.lock_clause,
    conflict: self.conflict,
    delete_key: self.delete_key,
    offset: self.offset,
    limit: self.limit,
    native_delete_limit: self.native_delete_limit,
  }
}

///|
pub fn Builder::where_(self : Builder, condition : Cond) -> Builder {
  self.cond = condition
  self
}

///|
pub fn Builder::limit(self : Builder, limit : Int32) -> Builder {
  self.limit = limit
  self
}

///|
pub fn Builder::offset(self : Builder, offset : Int32) -> Builder {
  self.offset = offset
  self
}

///|
pub fn Builder::page(self : Builder, page : Int32, per_page : Int32) -> Builder {
  if page == 0 && per_page == 0 {
    return self
  }
  let normalized_page = if page < 1 { 1 } else { page }
  self.limit = per_page
  self.offset = (normalized_page - 1) * per_page
  self
}

///|
pub fn Builder::order_by(self : Builder, order_by : String) -> Builder {
  let trimmed = order_by.trim().to_owned()
  if trimmed != "" {
    self.order_bys.push(trimmed)
  }
  self
}

///|
pub fn Builder::order_bys(self : Builder, order_bys : Array[String]) -> Builder {
  for order_by in order_bys {
    ignore(self.order_by(order_by))
  }
  self
}

///|
pub fn Builder::group_by(self : Builder, fields : Array[String]) -> Builder {
  self.group_bys.append(normalize_fields(fields))
  self
}

///|
pub fn Builder::group_by_fields(
  self : Builder,
  columns : Array[ColumnRef],
) -> Builder {
  for column in columns {
    self.group_bys.push(column.ref().to_string())
  }
  self
}

///|
pub fn Builder::window(self : Builder, definitions : Array[String]) -> Builder {
  self.windows.append(normalize_fields(definitions))
  self
}

///|
pub fn Builder::having(self : Builder, condition : Cond) -> Builder {
  self.having = condition
  self
}

///|
pub fn Builder::distinct(self : Builder) -> Builder {
  self.distinct = true
  self
}

///|
pub fn Builder::distinct_on(self : Builder, fields : Array[String]) -> Builder {
  self.distinct_on = normalize_fields(fields)
  self
}

///|
pub fn Builder::returning(self : Builder, fields : Array[String]) -> Builder {
  self.returning = normalize_fields(fields)
  self
}

///|
pub fn Builder::returning_fields(
  self : Builder,
  columns : Array[ColumnRef],
) -> Builder {
  self.returning = columns.map(column => column.ref().to_string())
  self
}

///|
pub fn Builder::returning_all(self : Builder) -> Builder {
  self.returning = ["*"]
  self
}

///|
pub fn Builder::for_clause(self : Builder, clause : String) -> Builder {
  let trimmed = clause.trim().to_owned()
  if trimmed != "" {
    self.lock_clause = Some(LockClause::Raw(trimmed))
  }
  self
}

///|
pub fn Builder::for_update(self : Builder) -> Builder {
  self.lock_clause = Some(LockClause::For("UPDATE", ""))
  self
}

///|
pub fn Builder::for_share(self : Builder) -> Builder {
  self.lock_clause = Some(LockClause::For("SHARE", ""))
  self
}

///|
pub fn Builder::for_update_skip_locked(self : Builder) -> Builder {
  self.lock_clause = Some(LockClause::For("UPDATE", "SKIP LOCKED"))
  self
}

///|
pub fn Builder::for_share_skip_locked(self : Builder) -> Builder {
  self.lock_clause = Some(LockClause::For("SHARE", "SKIP LOCKED"))
  self
}

///|
pub fn Builder::without_locking(self : Builder) -> Builder {
  let copied = self.copy()
  copied.lock_clause = None
  copied
}

///|
pub fn Builder::without_delete_subquery(self : Builder) -> Builder {
  let copied = self.copy()
  copied.native_delete_limit = true
  copied
}

///|
pub fn Builder::with_cte(
  self : Builder,
  name : String,
  query : Builder,
) -> Builder {
  self.with_clauses.push({
    name: name.trim().to_owned(),
    query,
    recursive: false,
  })
  self
}

///|
pub fn Builder::with_recursive(
  self : Builder,
  name : String,
  query : Builder,
) -> Builder {
  self.with_clauses.push({
    name: name.trim().to_owned(),
    query,
    recursive: true,
  })
  self
}

///|
fn Builder::add_join(
  self : Builder,
  kind : String,
  table_name : String,
  expr : Expr?,
  lateral : Bool,
  on : Cond,
) -> Builder {
  self.joins.push({ kind, table_name, expr, lateral, on, })
  self
}

///|
pub fn Builder::join(self : Builder, table_name : String, on : Cond) -> Builder {
  self.add_join("JOIN", table_name.trim().to_owned(), None, false, on)
}

///|
pub fn Builder::join_table(
  self : Builder,
  table : TableRef,
  on : Cond,
) -> Builder {
  self.add_join("JOIN", "", Some(table.to_expr()), false, on)
}

///|
pub fn Builder::left_join(
  self : Builder,
  table_name : String,
  on : Cond,
) -> Builder {
  self.add_join("LEFT JOIN", table_name.trim().to_owned(), None, false, on)
}

///|
pub fn Builder::left_join_table(
  self : Builder,
  table : TableRef,
  on : Cond,
) -> Builder {
  self.add_join("LEFT JOIN", "", Some(table.to_expr()), false, on)
}

///|
pub fn Builder::right_join(
  self : Builder,
  table_name : String,
  on : Cond,
) -> Builder {
  self.add_join("RIGHT JOIN", table_name.trim().to_owned(), None, false, on)
}

///|
pub fn Builder::right_join_table(
  self : Builder,
  table : TableRef,
  on : Cond,
) -> Builder {
  self.add_join("RIGHT JOIN", "", Some(table.to_expr()), false, on)
}

///|
pub fn Builder::full_join(
  self : Builder,
  table_name : String,
  on : Cond,
) -> Builder {
  self.add_join("FULL JOIN", table_name.trim().to_owned(), None, false, on)
}

///|
pub fn Builder::full_join_table(
  self : Builder,
  table : TableRef,
  on : Cond,
) -> Builder {
  self.add_join("FULL JOIN", "", Some(table.to_expr()), false, on)
}

///|
pub fn Builder::cross_join(self : Builder, table_name : String) -> Builder {
  self.add_join(
    "CROSS JOIN",
    table_name.trim().to_owned(),
    None,
    false,
    Cond::Empty,
  )
}

///|
pub fn Builder::cross_join_table(self : Builder, table : TableRef) -> Builder {
  self.add_join("CROSS JOIN", "", Some(table.to_expr()), false, Cond::Empty)
}

///|
pub fn Builder::join_expr(
  self : Builder,
  expression : Expr,
  on : Cond,
) -> Builder {
  self.add_join("JOIN", "", Some(expression), false, on)
}

///|
pub fn Builder::join_lateral(
  self : Builder,
  query : Builder,
  alias : String,
  on : Cond,
) -> Builder {
  self.add_lateral_join("JOIN", query, alias, on)
}

///|
pub fn Builder::left_join_lateral(
  self : Builder,
  query : Builder,
  alias : String,
  on : Cond,
) -> Builder {
  self.add_lateral_join("LEFT JOIN", query, alias, on)
}

///|
fn Builder::add_lateral_join(
  self : Builder,
  kind : String,
  query : Builder,
  alias : String,
  on : Cond,
) -> Builder {
  let expression = if alias.trim().to_owned() == "" {
    sub_query(query)
  } else {
    Expr::Wrapper("", sub_query(query), " AS " + alias.trim().to_owned())
  }
  self.add_join(kind, "", Some(expression), true, on)
}

///|
pub fn Builder::update_from(self : Builder, tables : Array[String]) -> Builder {
  self.update_from.append(normalize_fields(tables))
  self
}

///|
pub fn Builder::using_tables(self : Builder, tables : Array[String]) -> Builder {
  self.using_tables.append(normalize_fields(tables))
  self
}

///|
pub fn Builder::values(self : Builder, rows : Array[H]) -> Builder {
  self.rows = rows
  self
}

///|
pub fn Builder::insert_columns(
  self : Builder,
  columns : Array[String],
) -> Builder {
  self.insert_columns = normalize_fields(columns)
  self
}

///|
pub fn Builder::from_select(
  self : Builder,
  query : Builder,
  columns : Array[String],
) -> Builder {
  self.insert_query = Some(query)
  if columns.length() > 0 {
    self.insert_columns = normalize_fields(columns)
  }
  self
}

///|
pub fn Builder::delete_key(self : Builder, column : String) -> Builder {
  let trimmed = column.trim().to_owned()
  if trimmed != "" {
    self.delete_key = trimmed
  }
  self
}

///|
pub fn Builder::delete_key_field(self : Builder, column : ColumnRef) -> Builder {
  self.delete_key = column.ref().to_string()
  self
}

///|
pub fn Builder::on_conflict_do_nothing(
  self : Builder,
  columns : Array[String],
) -> Builder {
  self.conflict = Some({
    target: normalize_fields(columns),
    constraint_name: "",
    do_nothing: true,
    set: Map([]),
  })
  self
}

///|
pub fn Builder::on_conflict_on_constraint_do_nothing(
  self : Builder,
  constraint_name : String,
) -> Builder {
  self.conflict = Some({
    target: [],
    constraint_name: constraint_name.trim().to_owned(),
    do_nothing: true,
    set: Map([]),
  })
  self
}

///|
pub fn Builder::on_conflict_do_update(
  self : Builder,
  columns : Array[String],
  values : H,
) -> Builder {
  self.conflict = Some({
    target: normalize_fields(columns),
    constraint_name: "",
    do_nothing: false,
    set: values,
  })
  self
}

///|
pub fn Builder::on_conflict_on_constraint_do_update(
  self : Builder,
  constraint_name : String,
  values : H,
) -> Builder {
  self.conflict = Some({
    target: [],
    constraint_name: constraint_name.trim().to_owned(),
    do_nothing: false,
    set: values,
  })
  self
}

///|
fn Builder::add_set_operation(
  self : Builder,
  kind : String,
  query : Builder,
) -> Builder {
  self.set_ops.push({ kind, query, })
  self
}

///|
pub fn Builder::union(self : Builder, query : Builder) -> Builder {
  self.add_set_operation("UNION", query)
}

///|
pub fn Builder::union_all(self : Builder, query : Builder) -> Builder {
  self.add_set_operation("UNION ALL", query)
}

///|
pub fn Builder::intersect(self : Builder, query : Builder) -> Builder {
  self.add_set_operation("INTERSECT", query)
}

///|
pub fn Builder::intersect_all(self : Builder, query : Builder) -> Builder {
  self.add_set_operation("INTERSECT ALL", query)
}

///|
pub fn Builder::except(self : Builder, query : Builder) -> Builder {
  self.add_set_operation("EXCEPT", query)
}

///|
pub fn Builder::except_all(self : Builder, query : Builder) -> Builder {
  self.add_set_operation("EXCEPT ALL", query)
}

///|
pub fn Builder::kind(self : Builder) -> StatementKind {
  self.kind
}

///|
pub fn Builder::table_name(self : Builder) -> String {
  self.table_name
}

///|
pub fn Builder::insert_values(self : Builder) -> H {
  self.vals
}

///|
pub fn Builder::insert_rows(self : Builder) -> Array[H] {
  self.rows
}

///|
pub fn Builder::conflict_target(self : Builder) -> Array[String] {
  match self.conflict {
    Some(conflict) => conflict.target.copy()
    None => []
  }
}

///|
pub fn Builder::to_sql(self : Builder) -> (String, NamedArgs) raise SqlError {
  let state = BuildState::new()
  let sql = match self.kind {
    Select => build_select(self, state)
    Insert => build_insert(self, state)
    Update => build_update(self, state)
    Delete => build_delete(self, state)
  }
  (sql, state.args)
}

///|
pub impl Stmt for Builder with fn to_sql(self) {
  Builder::to_sql(self)
}

///|
pub impl Stmt for Builder with fn kind(self) {
  Builder::kind(self)
}

///|
pub impl Stmt for Builder with fn table_name(self) {
  Builder::table_name(self)
}

///|
pub impl Stmt for Builder with fn insert_values(self) {
  Builder::insert_values(self)
}

///|
pub impl Stmt for Builder with fn insert_rows(self) {
  Builder::insert_rows(self)
}

///|
pub impl Stmt for Builder with fn conflict_target(self) {
  Builder::conflict_target(self)
}

///|
pub impl Stmt for Builder with fn without_locking(self) {
  Builder::without_locking(self)
}

///|
pub impl Stmt for Builder with fn without_delete_subquery(self) {
  Builder::without_delete_subquery(self)
}
