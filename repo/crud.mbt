///|
fn schema_ref(schema : @db.Table) -> @sql.TableRef {
  @sql.table_of(schema.name)
}

///|
fn select_schema(schema : @db.Table) -> @sql.Builder {
  let table = schema_ref(schema)
  @sql.select_fields([table.all_fields()]).from_table(table)
}

///|
pub fn[T : FromJson] create_from(
  database : DB,
  schema : @db.Table,
  values : @sql.H,
) -> T? raise {
  insert(database, schema, @sql.insert(values).into_table(schema_ref(schema)))
}

///|
pub fn[T : FromJson] create_from_current(
  schema : @db.Table,
  values : @sql.H,
) -> T? raise {
  create_from(current_db(), schema, values)
}

///|
pub fn[T : FromJson] find_by(
  database : DB,
  schema : @db.Table,
  values : @sql.H,
) -> Array[T] raise {
  find(
    database,
    schema,
    select_schema(schema).where_(@sql.match_fields(schema_ref(schema), values)),
  )
}

///|
pub fn[T : FromJson] find_by_current(
  schema : @db.Table,
  values : @sql.H,
) -> Array[T] raise {
  find_by(current_db(), schema, values)
}

///|
pub fn[T : FromJson] find_one_by(
  database : DB,
  schema : @db.Table,
  values : @sql.H,
) -> T? raise {
  find_one(
    database,
    schema,
    select_schema(schema).where_(@sql.match_fields(schema_ref(schema), values)),
  )
}

///|
pub fn[T : FromJson] find_by_id(
  database : DB,
  schema : @db.Table,
  id : Int64,
) -> T? raise {
  let table = schema_ref(schema)
  find_one(
    database,
    schema,
    select_schema(schema).where_(@sql.field_eq(table.field("id"), @sql.val(id))),
  )
}

///|
pub fn[T : FromJson] find_all(
  database : DB,
  schema : @db.Table,
) -> Array[T] raise {
  find(database, schema, select_schema(schema))
}

///|
pub fn[T : FromJson] find_all_current(schema : @db.Table) -> Array[T] raise {
  find_all(current_db(), schema)
}

///|
pub fn update_where(
  database : DB,
  schema : @db.Table,
  values : @sql.H,
  condition : @sql.Cond,
) -> Unit raise {
  update(
    database,
    @sql.update_table(schema_ref(schema)).set(values).where_(condition),
  )
}

///|
pub fn update_by_id(
  database : DB,
  schema : @db.Table,
  id : Int64,
  values : @sql.H,
) -> Unit raise {
  let table = schema_ref(schema)
  update_where(
    database,
    schema,
    values,
    @sql.field_eq(table.field("id"), @sql.val(id)),
  )
}

///|
pub fn update_every(
  database : DB,
  schema : @db.Table,
  values : @sql.H,
) -> Unit raise {
  update(database, @sql.update_table(schema_ref(schema)).set(values))
}

///|
pub fn delete_where(
  database : DB,
  schema : @db.Table,
  values : @sql.H,
) -> Unit raise {
  delete(
    database,
    @sql.delete_from(schema_ref(schema)).where_(
      @sql.match_fields(schema_ref(schema), values),
    ),
  )
}

///|
pub fn delete_by_id(
  database : DB,
  schema : @db.Table,
  id : Int64,
) -> Unit raise {
  let table = schema_ref(schema)
  delete(
    database,
    @sql.delete_from(table).where_(
      @sql.field_eq(table.field("id"), @sql.val(id)),
    ),
  )
}

///|
pub fn delete_every(database : DB, schema : @db.Table) -> Unit raise {
  delete(database, @sql.delete_from(schema_ref(schema)))
}

///|
pub fn exists_where(
  database : DB,
  schema : @db.Table,
  values : @sql.H,
) -> Bool raise {
  let table = schema_ref(schema)
  exists(
    database,
    @sql.select_columns(["count(*)"])
    .from_table(table)
    .where_(@sql.match_fields(table, values))
    .limit(1),
  )
}

///|
pub fn count_where(
  database : DB,
  schema : @db.Table,
  values : @sql.H,
) -> Int64 raise {
  let table = schema_ref(schema)
  count(
    database,
    @sql.select_columns(["count(*)"])
    .from_table(table)
    .where_(@sql.match_fields(table, values)),
  )
}

///|
pub fn count_every(database : DB, schema : @db.Table) -> Int64 raise {
  count_where(database, schema, Map([]))
}
