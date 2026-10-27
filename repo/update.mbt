///|
pub fn[S : @sql.Stmt] update_affected_with(
  executor : Executor,
  stmt : S,
) -> Int64 raise {
  executor.execute(stmt)
}

///|
pub fn[S : @sql.Stmt] update_affected(database : DB, stmt : S) -> Int64 raise {
  update_affected_with(database.executor(), stmt)
}

///|
pub fn[S : @sql.Stmt] update_with(executor : Executor, stmt : S) -> Unit raise {
  ignore(update_affected_with(executor, stmt))
}

///|
pub fn[S : @sql.Stmt] update(database : DB, stmt : S) -> Unit raise {
  update_with(database.executor(), stmt)
}
