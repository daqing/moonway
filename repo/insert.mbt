///|
pub fn[T : FromJson, S : @sql.Stmt] insert_with(
  executor : Executor,
  schema : @db.Table,
  stmt : S,
) -> T? raise {
  let records = executor.scan_records(prepare_builder(executor.driver, stmt))
  let mut result : T? = None
  for record in records {
    result = Some(decode_record(schema, record))
  }
  result
}

///|
pub fn[T : FromJson, S : @sql.Stmt] insert(
  database : DB,
  schema : @db.Table,
  stmt : S,
) -> T? raise {
  insert_with(database.executor(), schema, stmt)
}

///|
pub fn[T : FromJson, S : @sql.Stmt] create(
  database : DB,
  schema : @db.Table,
  stmt : S,
) -> T? raise {
  insert(database, schema, stmt)
}

///|
pub fn[T : FromJson, S : @sql.Stmt] create_with(
  executor : Executor,
  schema : @db.Table,
  stmt : S,
) -> T? raise {
  insert_with(executor, schema, stmt)
}

///|
pub fn[S : @sql.Stmt] insert_map_with(
  executor : Executor,
  stmt : S,
) -> Record? raise {
  let records = executor.scan_records(prepare_builder(executor.driver, stmt))
  if records.length() > 1 {
    raise RepoError::CountNotMatch
  }
  records.get(0)
}

///|
pub fn[S : @sql.Stmt] insert_map(database : DB, stmt : S) -> Record? raise {
  insert_map_with(database.executor(), stmt)
}
