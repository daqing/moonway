///|
fn tx_test_schema() -> @db.Table {
  @db.table("tx_items", [
    @db.column("id", @db.IntT, primary=true),
    @db.column("title", @db.TextT),
  ])
}

///|
test "transaction commits and rolls back real sqlite statements" {
  let database = @repo.new_db(":memory:")
  let schema = tx_test_schema()
  assert_true(database.raw().exec(schema.create_sql()))
  @repo.with_tx(database, tx => {
    ignore(
      tx
      .executor()
      .exec_sql("INSERT INTO tx_items (title) VALUES ('committed')"),
    )
  })
  assert_eq(database.raw().count(schema), 1)
  try
    @repo.with_tx(database, tx => {
      ignore(
        tx
        .executor()
        .exec_sql("INSERT INTO tx_items (title) VALUES ('rolled back')"),
      )
      raise @repo.RepoError::InvalidRecord("force rollback")
    })
  catch {
    @repo.RepoError::InvalidRecord("force rollback") => ()
    _ => fail("unexpected transaction error")
  } noraise {
    _ => fail("expected rollback")
  }
  assert_eq(database.raw().count(schema), 1)
  database.close()
}
