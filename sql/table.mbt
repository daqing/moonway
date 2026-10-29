///|
pub fn[T : Table] all(table : T) -> Builder {
  let reference = table_for(table)
  select_fields([reference.all_fields()]).from_table(reference)
}

///|
pub fn[T : Table] find_by(table : T, values : H) -> Builder {
  find_by_cond(table, match_fields(table_for(table), values))
}

///|
pub fn[T : Table] find_by_cond(table : T, condition : Cond) -> Builder {
  let reference = table_for(table)
  select_fields([reference.all_fields()])
  .from_table(reference)
  .where_(condition)
}

///|
pub fn[T : Table] create(table : T, values : H) -> Builder {
  insert(values).into_table(table_for(table))
}

///|
pub fn[T : Table] update_all(table : T, values : H) -> Builder {
  update_table(table_for(table)).set(values)
}

///|
pub fn[T : Table] delete_by_id(table : T, id : Int64) -> Builder {
  let reference = table_for(table)
  delete_from(reference).where_(field_eq(reference.field("id"), val(id)))
}

///|
pub fn[T : Table] exists(table : T, values : H) -> Builder {
  select_columns(["count(*)"])
  .from_table(table_for(table))
  .where_(match_fields(table_for(table), values))
  .limit(1)
}
