///|
pub fn[S : @sql.Stmt] delete_affected_with(
  executor : Executor,
  stmt : S,
) -> Int64 raise {
  executor.execute(stmt)
}

///|
pub fn[S : @sql.Stmt] delete_affected(database : DB, stmt : S) -> Int64 raise {
  delete_affected_with(database.executor(), stmt)
}

///|
pub fn[S : @sql.Stmt] delete_with(executor : Executor, stmt : S) -> Unit raise {
  ignore(delete_affected_with(executor, stmt))
}

///|
pub fn[S : @sql.Stmt] delete(database : DB, stmt : S) -> Unit raise {
  delete_with(database.executor(), stmt)
}
