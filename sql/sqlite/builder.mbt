///|
pub struct Builder {
  priv inner : @sql.Builder
}

///|
fn wrap(inner : @sql.Builder) -> Builder {
  { inner, }
}

///|
pub using @sql {
  type Value,
  type NamedArgs,
  type H,
  type Expr,
  type Cond,
  type Identifier,
  type TableRef,
  type ColumnRef,
  type TableName,
  type FieldName,
  trait Table,
  type StatementKind,
  type SqlError,
  val,
  null,
  h,
  named_args,
  ident,
  table_of,
  table_of_parts,
  table_alias,
  ref,
  ref_as,
  col,
  field,
  quote_identifier,
  table_for,
  field_for,
  expr,
  expr_named,
  raw,
  column,
  excluded,
  default,
  func,
  op,
  cast,
  empty_cond,
  condition,
  compare,
  eq,
  not_eq,
  gt,
  gte,
  lt,
  lte,
  like,
  not_like,
  field_eq,
  eq_ref,
  field_not_eq,
  field_gt,
  field_gte,
  field_lt,
  field_lte,
  field_like,
  h_cond,
  match_fields,
  h_cond_ref,
  in_cond,
  not_in_cond,
  all_of,
  any_of,
  not,
  is_null,
  is_not_null,
  between,
  not_between,
  raw_condition,
}

///|
pub fn select(fields : String) -> Builder {
  wrap(@sql.select(fields))
}

///|
pub fn select_columns(fields : Array[String]) -> Builder {
  wrap(@sql.select_columns(fields))
}

///|
pub fn select_fields(fields : Array[@sql.ColumnRef]) -> Builder {
  wrap(@sql.select_fields(fields))
}

///|
pub fn select_refs(fields : Array[@sql.ColumnRef]) -> Builder {
  select_fields(fields)
}

///|
pub fn insert(values : @sql.H) -> Builder {
  wrap(@sql.insert(values))
}

///|
pub fn insert_rows(rows : Array[@sql.H]) -> Builder {
  wrap(@sql.insert_rows(rows))
}

///|
pub fn update(table_name : String) -> Builder {
  wrap(@sql.update(table_name))
}

///|
pub fn update_table(table : @sql.TableRef) -> Builder {
  wrap(@sql.update_table(table))
}

///|
pub fn delete() -> Builder {
  wrap(@sql.delete())
}

///|
pub fn delete_from(table : @sql.TableRef) -> Builder {
  wrap(@sql.delete_from(table))
}

///|
pub fn[T : @sql.Table] all(table : T) -> Builder {
  wrap(@sql.all(table))
}

///|
pub fn[T : @sql.Table] find_by(table : T, values : @sql.H) -> Builder {
  wrap(@sql.find_by(table, values))
}

///|
pub fn[T : @sql.Table] find_by_cond(
  table : T,
  condition : @sql.Cond,
) -> Builder {
  wrap(@sql.find_by_cond(table, condition))
}

///|
pub fn[T : @sql.Table] create(table : T, values : @sql.H) -> Builder {
  wrap(@sql.create(table, values))
}

///|
pub fn[T : @sql.Table] update_all(table : T, values : @sql.H) -> Builder {
  wrap(@sql.update_all(table, values))
}

///|
pub fn[T : @sql.Table] delete_by_id(table : T, id : Int64) -> Builder {
  wrap(@sql.delete_by_id(table, id))
}

///|
pub fn[T : @sql.Table] exists(table : T, values : @sql.H) -> Builder {
  wrap(@sql.exists(table, values))
}

///|
pub fn sub_query(query : Builder) -> @sql.Expr {
  @sql.sub_query(query.inner)
}

///|
pub fn exists_query(query : Builder) -> @sql.Cond {
  @sql.exists_query(query.inner)
}

///|
pub fn not_exists_query(query : Builder) -> @sql.Cond {
  @sql.not_exists_query(query.inner)
}

///|
pub fn Builder::columns(self : Builder, fields : Array[String]) -> Builder {
  wrap(self.inner.columns(fields))
}

///|
pub fn Builder::fields(
  self : Builder,
  fields : Array[@sql.ColumnRef],
) -> Builder {
  wrap(self.inner.fields(fields))
}

///|
pub fn Builder::from(self : Builder, table_name : String) -> Builder {
  wrap(self.inner.from(table_name))
}

///|
pub fn Builder::from_table(self : Builder, table : @sql.TableRef) -> Builder {
  wrap(self.inner.from_table(table))
}

///|
pub fn Builder::from_expr(self : Builder, expression : @sql.Expr) -> Builder {
  wrap(self.inner.from_expr(expression))
}

///|
pub fn Builder::from_sub_query(
  self : Builder,
  query : Builder,
  alias : String,
) -> Builder {
  wrap(self.inner.from_sub_query(query.inner, alias))
}

///|
pub fn Builder::where_(self : Builder, condition : @sql.Cond) -> Builder {
  wrap(self.inner.where_(condition))
}

///|
pub fn Builder::limit(self : Builder, limit : Int32) -> Builder {
  wrap(self.inner.limit(limit))
}

///|
pub fn Builder::offset(self : Builder, offset : Int32) -> Builder {
  wrap(self.inner.offset(offset))
}

///|
pub fn Builder::page(self : Builder, page : Int32, per_page : Int32) -> Builder {
  wrap(self.inner.page(page, per_page))
}

///|
pub fn Builder::order_by(self : Builder, order_by : String) -> Builder {
  wrap(self.inner.order_by(order_by))
}

///|
pub fn Builder::order_bys(self : Builder, order_bys : Array[String]) -> Builder {
  wrap(self.inner.order_bys(order_bys))
}

///|
pub fn Builder::group_by(self : Builder, fields : Array[String]) -> Builder {
  wrap(self.inner.group_by(fields))
}

///|
pub fn Builder::group_by_fields(
  self : Builder,
  fields : Array[@sql.ColumnRef],
) -> Builder {
  wrap(self.inner.group_by_fields(fields))
}

///|
pub fn Builder::window(self : Builder, definitions : Array[String]) -> Builder {
  wrap(self.inner.window(definitions))
}

///|
pub fn Builder::having(self : Builder, condition : @sql.Cond) -> Builder {
  wrap(self.inner.having(condition))
}

///|
pub fn Builder::distinct(self : Builder) -> Builder {
  wrap(self.inner.distinct())
}

///|
pub fn Builder::join(
  self : Builder,
  table_name : String,
  on : @sql.Cond,
) -> Builder {
  wrap(self.inner.join(table_name, on))
}

///|
pub fn Builder::join_table(
  self : Builder,
  table : @sql.TableRef,
  on : @sql.Cond,
) -> Builder {
  wrap(self.inner.join_table(table, on))
}

///|
pub fn Builder::left_join(
  self : Builder,
  table_name : String,
  on : @sql.Cond,
) -> Builder {
  wrap(self.inner.left_join(table_name, on))
}

///|
pub fn Builder::left_join_table(
  self : Builder,
  table : @sql.TableRef,
  on : @sql.Cond,
) -> Builder {
  wrap(self.inner.left_join_table(table, on))
}

///|
pub fn Builder::right_join(
  self : Builder,
  table_name : String,
  on : @sql.Cond,
) -> Builder {
  wrap(self.inner.right_join(table_name, on))
}

///|
pub fn Builder::right_join_table(
  self : Builder,
  table : @sql.TableRef,
  on : @sql.Cond,
) -> Builder {
  wrap(self.inner.right_join_table(table, on))
}

///|
pub fn Builder::full_join(
  self : Builder,
  table_name : String,
  on : @sql.Cond,
) -> Builder {
  wrap(self.inner.full_join(table_name, on))
}

///|
pub fn Builder::full_join_table(
  self : Builder,
  table : @sql.TableRef,
  on : @sql.Cond,
) -> Builder {
  wrap(self.inner.full_join_table(table, on))
}

///|
pub fn Builder::cross_join(self : Builder, table_name : String) -> Builder {
  wrap(self.inner.cross_join(table_name))
}

///|
pub fn Builder::cross_join_table(
  self : Builder,
  table : @sql.TableRef,
) -> Builder {
  wrap(self.inner.cross_join_table(table))
}

///|
pub fn Builder::join_expr(
  self : Builder,
  expression : @sql.Expr,
  on : @sql.Cond,
) -> Builder {
  wrap(self.inner.join_expr(expression, on))
}

///|
pub fn Builder::with_cte(
  self : Builder,
  name : String,
  query : Builder,
) -> Builder {
  wrap(self.inner.with_cte(name, query.inner))
}

///|
pub fn Builder::with_recursive(
  self : Builder,
  name : String,
  query : Builder,
) -> Builder {
  wrap(self.inner.with_recursive(name, query.inner))
}

///|
pub fn Builder::union(self : Builder, query : Builder) -> Builder {
  wrap(self.inner.union(query.inner))
}

///|
pub fn Builder::union_all(self : Builder, query : Builder) -> Builder {
  wrap(self.inner.union_all(query.inner))
}

///|
pub fn Builder::intersect(self : Builder, query : Builder) -> Builder {
  wrap(self.inner.intersect(query.inner))
}

///|
pub fn Builder::intersect_all(self : Builder, query : Builder) -> Builder {
  wrap(self.inner.intersect_all(query.inner))
}

///|
pub fn Builder::except(self : Builder, query : Builder) -> Builder {
  wrap(self.inner.except(query.inner))
}

///|
pub fn Builder::except_all(self : Builder, query : Builder) -> Builder {
  wrap(self.inner.except_all(query.inner))
}

///|
pub fn Builder::into(self : Builder, table_name : String) -> Builder {
  wrap(self.inner.into(table_name))
}

///|
pub fn Builder::into_table(self : Builder, table : @sql.TableRef) -> Builder {
  wrap(self.inner.into_table(table))
}

///|
pub fn Builder::values(self : Builder, rows : Array[@sql.H]) -> Builder {
  wrap(self.inner.values(rows))
}

///|
pub fn Builder::insert_columns(
  self : Builder,
  columns : Array[String],
) -> Builder {
  wrap(self.inner.insert_columns(columns))
}

///|
pub fn Builder::from_select(
  self : Builder,
  query : Builder,
  columns : Array[String],
) -> Builder {
  wrap(self.inner.from_select(query.inner, columns))
}

///|
pub fn Builder::on_conflict_do_nothing(
  self : Builder,
  columns : Array[String],
) -> Builder {
  wrap(self.inner.on_conflict_do_nothing(columns))
}

///|
pub fn Builder::on_conflict_do_update(
  self : Builder,
  columns : Array[String],
  values : @sql.H,
) -> Builder {
  wrap(self.inner.on_conflict_do_update(columns, values))
}

///|
pub fn Builder::set(self : Builder, values : @sql.H) -> Builder {
  wrap(self.inner.set(values))
}

///|
pub fn Builder::delete_key(self : Builder, column : String) -> Builder {
  wrap(self.inner.delete_key(column))
}

///|
pub fn Builder::delete_key_field(
  self : Builder,
  column : @sql.ColumnRef,
) -> Builder {
  wrap(self.inner.delete_key_field(column))
}

///|
pub fn Builder::returning(self : Builder, fields : Array[String]) -> Builder {
  wrap(self.inner.returning(fields))
}

///|
pub fn Builder::returning_fields(
  self : Builder,
  fields : Array[@sql.ColumnRef],
) -> Builder {
  wrap(self.inner.returning_fields(fields))
}

///|
pub fn Builder::returning_all(self : Builder) -> Builder {
  wrap(self.inner.returning_all())
}

///|
pub fn Builder::without_locking(self : Builder) -> Builder {
  wrap(self.inner.without_locking())
}

///|
pub fn Builder::without_delete_subquery(self : Builder) -> Builder {
  wrap(self.inner.without_delete_subquery())
}

///|
pub fn Builder::to_sql(
  self : Builder,
) -> (String, @sql.NamedArgs) raise @sql.SqlError {
  self.inner.to_sql()
}

///|
pub impl @sql.Stmt for Builder with fn to_sql(self) {
  self.inner.to_sql()
}

///|
pub impl @sql.Stmt for Builder with fn kind(self) {
  self.inner.kind()
}

///|
pub impl @sql.Stmt for Builder with fn table_name(self) {
  self.inner.table_name()
}

///|
pub impl @sql.Stmt for Builder with fn insert_values(self) {
  self.inner.insert_values()
}

///|
pub impl @sql.Stmt for Builder with fn insert_rows(self) {
  self.inner.insert_rows()
}

///|
pub impl @sql.Stmt for Builder with fn conflict_target(self) {
  self.inner.conflict_target()
}

///|
pub impl @sql.Stmt for Builder with fn without_locking(self) {
  self.without_locking()
}

///|
pub impl @sql.Stmt for Builder with fn without_delete_subquery(self) {
  self.without_delete_subquery()
}
