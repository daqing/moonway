///|
fn Executor::prepare_statement(
  self : Executor,
  prepared : Prepared,
) -> @sqlite.Statement raise RepoError {
  if self.driver != Driver::SQLite {
    raise RepoError::UnsupportedDriver("execution requires SQLite")
  }
  match self.conn.inner.prepare(prepared.query) {
    Some(stmt) =>
      if stmt.bind_all(prepared.args.map(value_to_sql)) {
        stmt
      } else {
        stmt.finalize()
        raise RepoError::PrepareFailed(self.error_message())
      }
    None => raise RepoError::PrepareFailed(self.error_message())
  }
}

///|
fn Executor::error_message(self : Executor) -> String {
  bytes_to_string(self.conn.inner.errmsg())
}

///|
pub fn Executor::exec_sql(
  self : Executor,
  sql : String,
) -> Int64 raise RepoError {
  self.execute_prepared({ query: sql, args: [], })
}

///|
pub fn Executor::execute_prepared(
  self : Executor,
  prepared : Prepared,
) -> Int64 raise RepoError {
  let stmt = self.prepare_statement(prepared)
  let executed = stmt.execute()
  stmt.finalize()
  if executed {
    self.conn.changes().to_int64()
  } else {
    raise RepoError::ExecuteFailed(self.error_message())
  }
}

///|
pub fn[S : @sql.Stmt] Executor::execute(
  self : Executor,
  stmt : S,
) -> Int64 raise {
  self.execute_prepared(prepare_builder(self.driver, stmt))
}

///|
pub fn[S : @sql.Stmt] Executor::preview(
  self : Executor,
  stmt : S,
) -> Prepared raise {
  prepare_builder(self.driver, stmt)
}

///|
pub fn[S : @sql.Stmt] preview(database : DB, stmt : S) -> Prepared raise {
  database.executor().preview(stmt)
}
