///|
pub fn[T : FromJson, S : @sql.Stmt] find_with(
  executor : Executor,
  schema : @db.Table,
  stmt : S,
) -> Array[T] raise {
  let prepared = prepare_builder(executor.driver, stmt)
  let records = executor.scan_records(prepared)
  let models : Array[T] = []
  for record in records {
    models.push(decode_record(schema, record))
  }
  models
}

///|
pub fn[T : FromJson, S : @sql.Stmt] find(
  database : DB,
  schema : @db.Table,
  stmt : S,
) -> Array[T] raise {
  find_with(database.executor(), schema, stmt)
}

///|
pub fn[T : FromJson, S : @sql.Stmt] find_one_with(
  executor : Executor,
  schema : @db.Table,
  stmt : S,
) -> T? raise {
  let rows : Array[T] = find_with(executor, schema, stmt)
  if rows.length() > 1 {
    raise RepoError::CountNotMatch
  }
  rows.get(0)
}

///|
pub fn[T : FromJson, S : @sql.Stmt] find_one(
  database : DB,
  schema : @db.Table,
  stmt : S,
) -> T? raise {
  find_one_with(database.executor(), schema, stmt)
}

///|
pub fn[S : @sql.Stmt] find_maps_with(
  executor : Executor,
  stmt : S,
) -> Array[Record] raise {
  executor.scan_records(prepare_builder(executor.driver, stmt))
}

///|
pub fn[S : @sql.Stmt] find_maps(database : DB, stmt : S) -> Array[Record] raise {
  find_maps_with(database.executor(), stmt)
}

///|
pub fn[S : @sql.Stmt] find_one_map_with(
  executor : Executor,
  stmt : S,
) -> Record? raise {
  let rows = find_maps_with(executor, stmt)
  if rows.length() > 1 {
    raise RepoError::CountNotMatch
  }
  rows.get(0)
}

///|
pub fn[S : @sql.Stmt] find_one_map(database : DB, stmt : S) -> Record? raise {
  find_one_map_with(database.executor(), stmt)
}

///|
pub fn[S : @sql.Stmt] preview_with(
  executor : Executor,
  stmt : S,
) -> Prepared raise {
  prepare_builder(executor.driver, stmt)
}
