///|
pub fn[S : @sql.Stmt] count_with(executor : Executor, stmt : S) -> Int64 raise {
  let records = find_maps_with(executor, stmt)
  guard records.get(0) is Some(record) else { return 0L }
  for _, value in record {
    match value_as_int64(value) {
      Some(count) => return count
      None => raise RepoError::InvalidRecord("count is not an integer")
    }
  }
  0L
}

///|
pub fn[S : @sql.Stmt] count(database : DB, stmt : S) -> Int64 raise {
  count_with(database.executor(), stmt)
}

///|
pub fn[S : @sql.Stmt] exists_with(executor : Executor, stmt : S) -> Bool raise {
  count_with(executor, stmt) > 0L
}

///|
pub fn[S : @sql.Stmt] exists(database : DB, stmt : S) -> Bool raise {
  exists_with(database.executor(), stmt)
}

///|
pub fn[S : @sql.Stmt] Tx::update(self : Tx, stmt : S) -> Unit raise {
  update_with(self.exec, stmt)
}

///|
pub fn[S : @sql.Stmt] Tx::update_affected(self : Tx, stmt : S) -> Int64 raise {
  update_affected_with(self.exec, stmt)
}

///|
pub fn[S : @sql.Stmt] Tx::delete(self : Tx, stmt : S) -> Unit raise {
  delete_with(self.exec, stmt)
}

///|
pub fn[S : @sql.Stmt] Tx::delete_affected(self : Tx, stmt : S) -> Int64 raise {
  delete_affected_with(self.exec, stmt)
}

///|
pub fn[S : @sql.Stmt] Tx::count(self : Tx, stmt : S) -> Int64 raise {
  count_with(self.exec, stmt)
}

///|
pub fn[S : @sql.Stmt] Tx::exists(self : Tx, stmt : S) -> Bool raise {
  exists_with(self.exec, stmt)
}
