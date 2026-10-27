///|
pub struct Tx {
  priv exec : Executor
}

///|
pub fn with_tx(database : DB, callback : (Tx) -> Unit raise) -> Unit raise {
  let executor = database.executor()
  if !executor.conn.inner.begin() {
    raise RepoError::ExecuteFailed(executor.error_message())
  }
  let tx = { exec: executor, }
  errdefer ignore(executor.conn.inner.rollback())
  callback(tx)
  if !executor.conn.inner.commit() {
    raise RepoError::ExecuteFailed(executor.error_message())
  }
}

///|
pub fn Tx::executor(self : Tx) -> Executor {
  self.exec
}

///|
pub fn Tx::raw(self : Tx) -> @db.Database {
  self.exec.conn
}
