///|
priv struct JoinDef {
  relation : Relation
  join_type : String
  condition : @sql.Cond?
}

///|
pub struct JoinQuery {
  priv database : DB
  priv primary : @db.Table
  priv joins : Array[JoinDef]
  priv mut conditions : @sql.Cond
  priv order_bys : Array[String]
  priv mut limit_value : Int32
  priv mut offset_value : Int32
}

///|
pub struct JoinResultSet {
  priv records : Array[Record]
}

///|
pub fn DB::join(self : DB, primary : @db.Table) -> JoinQuery {
  {
    database: self,
    primary,
    joins: [],
    conditions: @sql.Cond::Empty,
    order_bys: [],
    limit_value: -1,
    offset_value: -1,
  }
}

///|
pub fn join(primary : @db.Table) -> JoinQuery raise RepoError {
  current_db().join(primary)
}

///|
fn JoinQuery::add_join(
  self : JoinQuery,
  join_type : String,
  relation : Relation,
  condition : @sql.Cond?,
) -> JoinQuery {
  self.joins.push({ relation, join_type, condition, })
  self
}

///|
pub fn JoinQuery::joins(
  self : JoinQuery,
  relation : Relation,
  condition? : @sql.Cond,
) -> JoinQuery {
  self.add_join("JOIN", relation, condition)
}

///|
pub fn JoinQuery::left_joins(
  self : JoinQuery,
  relation : Relation,
  condition? : @sql.Cond,
) -> JoinQuery {
  self.add_join("LEFT JOIN", relation, condition)
}

///|
pub fn JoinQuery::right_joins(
  self : JoinQuery,
  relation : Relation,
  condition? : @sql.Cond,
) -> JoinQuery {
  self.add_join("RIGHT JOIN", relation, condition)
}

///|
pub fn JoinQuery::full_joins(
  self : JoinQuery,
  relation : Relation,
  condition? : @sql.Cond,
) -> JoinQuery {
  self.add_join("FULL JOIN", relation, condition)
}

///|
pub fn JoinQuery::cross_joins(
  self : JoinQuery,
  relation : Relation,
) -> JoinQuery {
  self.add_join("CROSS JOIN", relation, None)
}

///|
pub fn JoinQuery::where_(self : JoinQuery, condition : @sql.Cond) -> JoinQuery {
  self.conditions = condition
  self
}

///|
pub fn JoinQuery::order_by(self : JoinQuery, order : String) -> JoinQuery {
  self.order_bys.push(order)
  self
}

///|
pub fn JoinQuery::limit(self : JoinQuery, limit : Int32) -> JoinQuery {
  self.limit_value = limit
  self
}

///|
pub fn JoinQuery::offset(self : JoinQuery, offset : Int32) -> JoinQuery {
  self.offset_value = offset
  self
}

///|
pub fn JoinQuery::page(
  self : JoinQuery,
  page : Int32,
  per_page : Int32,
) -> JoinQuery {
  let normalized = if page < 1 { 1 } else { page }
  self.limit_value = per_page
  self.offset_value = (normalized - 1) * per_page
  self
}

///|
pub fn JoinQuery::build(self : JoinQuery) -> @sql.Builder {
  let primary = schema_ref(self.primary)
  let builder = @sql.select_columns(["*"]).from_table(primary)
  for join in self.joins {
    let related = schema_ref(join.relation.table)
    if join.join_type != "CROSS JOIN" {
      let base = join_condition(primary, related, join.relation)
      let condition = match join.condition {
        Some(extra) => @sql.all_of([base, extra])
        None => base
      }
      match join.join_type {
        "LEFT JOIN" => ignore(builder.left_join_table(related, condition))
        "RIGHT JOIN" => ignore(builder.right_join_table(related, condition))
        "FULL JOIN" => ignore(builder.full_join_table(related, condition))
        _ => ignore(builder.join_table(related, condition))
      }
    } else {
      ignore(builder.cross_join_table(related))
    }
  }
  ignore(builder.where_(self.conditions))
  for order in self.order_bys {
    ignore(builder.order_by(order))
  }
  if self.limit_value >= 0 {
    ignore(builder.limit(self.limit_value))
  }
  if self.offset_value >= 0 {
    ignore(builder.offset(self.offset_value))
  }
  builder
}

///|
fn join_condition(
  primary : @sql.TableRef,
  related : @sql.TableRef,
  relation : Relation,
) -> @sql.Cond {
  match relation.kind {
    BelongsTo =>
      @sql.compare(
        @sql.val(primary.field(relation.foreign_key)),
        "=",
        @sql.val(related.field(relation.primary_key)),
      )
    _ =>
      @sql.compare(
        @sql.val(primary.field(relation.primary_key)),
        "=",
        @sql.val(related.field(relation.foreign_key)),
      )
  }
}

///|
pub fn JoinQuery::find(self : JoinQuery) -> JoinResultSet raise {
  { records: find_maps(self.database, self.build()), }
}

///|
pub fn[T : FromJson] JoinQuery::find_into(self : JoinQuery) -> Array[T] raise {
  find(self.database, self.primary, self.build())
}

///|
pub fn JoinQuery::count(self : JoinQuery) -> Int64 raise {
  count(
    self.database,
    @sql.select_columns(["count(*)"]).from_sub_query(self.build(), "t"),
  )
}

///|
pub fn JoinResultSet::records(self : JoinResultSet) -> Array[Record] {
  self.records
}

///|
pub fn JoinResultSet::len(self : JoinResultSet) -> Int32 {
  self.records.length()
}

///|
pub fn JoinResultSet::is_empty(self : JoinResultSet) -> Bool {
  self.records.length() == 0
}
