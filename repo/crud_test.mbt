///|
struct Todo {
  id : Int32
  title : String
  completed : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
fn todo_schema() -> @db.Table {
  @db.table("todos", [
    @db.column("id", @db.IntT, primary=true),
    @db.column("title", @db.TextT),
    @db.column("completed", @db.BoolT),
  ])
}

///|
fn todo_database() -> (@repo.DB, @db.Table) raise {
  let database = @repo.new_db(":memory:")
  let schema = todo_schema()
  assert_true(database.raw().exec(schema.create_sql()))
  (database, schema)
}

///|
fn insert_todo(
  database : @repo.DB,
  schema : @db.Table,
  title : String,
  completed : Bool,
) -> Todo raise {
  let inserted : Todo? = @repo.insert(
    database,
    schema,
    @sql.insert(
      @sql.h([("title", @sql.val(title)), ("completed", @sql.val(completed))]),
    ).into_table(@sql.table_of(schema.name)),
  )
  inserted.unwrap()
}

///|
test "typed crud count exists and sqlite ilike fallback" {
  let (database, schema) = todo_database()
  let first = insert_todo(database, schema, "Alpha task", false)
  assert_true(first.id > 0)
  assert_eq(first.completed, false)
  insert_todo(database, schema, "Beta task", true) |> ignore
  let todos = @sql.table_of("todos")
  let rows : Array[Todo] = @repo.find(
    database,
    schema,
    @sql.select_fields([todos.all_fields()])
    .from_table(todos)
    .where_(@sql.field_ilike(todos.field("title"), @sql.val("%alpha%")))
    .for_update(),
  )
  assert_eq(rows.length(), 1)
  assert_eq(rows[0].title, "Alpha task")
  let affected = @repo.update_affected(
    database,
    @sql.update_table(todos)
    .set(@sql.h([("completed", @sql.val(true))]))
    .where_(@sql.field_eq(todos.field("id"), @sql.val(first.id))),
  )
  assert_eq(affected, 1L)
  let updated : Todo? = @repo.find_by_id(database, schema, first.id.to_int64())
  assert_true(updated.unwrap().completed)
  assert_eq(@repo.count_every(database, schema), 2L)
  assert_true(
    @repo.exists_where(
      database,
      schema,
      @sql.h([("title", @sql.val("Beta task"))]),
    ),
  )
  @repo.delete_by_id(database, schema, first.id.to_int64())
  assert_eq(@repo.count_every(database, schema), 1L)
  database.close()
}

///|
test "map crud and find_one cardinality" {
  let (database, schema) = todo_database()
  let todos = @sql.table_of("todos")
  let inserted = @repo.insert_map(
    database,
    @sql.insert(
      @sql.h([("title", @sql.val("duplicate")), ("completed", @sql.val(false))]),
    ).into_table(todos),
  )
  assert_eq(inserted.unwrap()["title"], @sql.Value::Text("duplicate"))
  insert_todo(database, schema, "duplicate", true) |> ignore
  let records = @repo.find_maps(
    database,
    @sql.select_fields([todos.all_fields()]).from_table(todos),
  )
  assert_eq(records.length(), 2)
  try
    @repo.find_one_map(
      database,
      @sql.select_fields([todos.all_fields()]).from_table(todos),
    )
  catch {
    @repo.RepoError::CountNotMatch => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected CountNotMatch")
  }
  @repo.update_where(
    database,
    schema,
    @sql.h([("completed", @sql.val(false))]),
    @sql.raw_condition("1=1", Map([])),
  )
  assert_eq(
    @repo.count_where(
      database,
      schema,
      @sql.h([("completed", @sql.val(false))]),
    ),
    2L,
  )
  @repo.delete_every(database, schema)
  assert_eq(@repo.count_every(database, schema), 0L)
  database.close()
}

///|
test "upsert returning and conflict no rows" {
  let database = @repo.new_db(":memory:")
  let schema = todo_schema()
  assert_true(
    database
    .raw()
    .exec(
      "CREATE TABLE todos (id INTEGER PRIMARY KEY, title TEXT UNIQUE, completed INTEGER)",
    ),
  )
  insert_todo(database, schema, "same", false) |> ignore
  let todos = @sql.table_of("todos")
  let skipped : Todo? = @repo.insert(
    database,
    schema,
    @sql.insert(
      @sql.h([("title", @sql.val("same")), ("completed", @sql.val(true))]),
    )
    .into_table(todos)
    .on_conflict_do_nothing(["title"]),
  )
  assert_true(skipped is None)
  let updated : Todo? = @repo.insert(
    database,
    schema,
    @sql.insert(
      @sql.h([("title", @sql.val("same")), ("completed", @sql.val(true))]),
    )
    .into_table(todos)
    .on_conflict_do_update(["title"], @sql.h([("completed", @sql.val(true))])),
  )
  assert_true(updated.unwrap().completed)
  assert_eq(@repo.count_every(database, schema), 1L)
  database.close()
}

///|
test "transaction executor supports typed insert and rollback" {
  let (database, schema) = todo_database()
  let todos = @sql.table_of("todos")
  @repo.with_tx(database, tx => {
    let inserted : Todo? = @repo.insert_with(
      tx.executor(),
      schema,
      @sql.insert(
        @sql.h([("title", @sql.val("inside")), ("completed", @sql.val(false))]),
      ).into_table(todos),
    )
    assert_true(inserted is Some(_))
    assert_eq(tx.count(@sql.select_columns(["count(*)"]).from_table(todos)), 1L)
  })
  try
    @repo.with_tx(database, tx => {
      let inserted : Todo? = @repo.insert_with(
        tx.executor(),
        schema,
        @sql.insert(
          @sql.h([
            ("title", @sql.val("rollback")),
            ("completed", @sql.val(true)),
          ]),
        ).into_table(todos),
      )
      ignore(inserted)
      raise @repo.RepoError::InvalidRecord("rollback")
    })
  catch {
    @repo.RepoError::InvalidRecord("rollback") => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected rollback")
  }
  assert_eq(@repo.count_every(database, schema), 1L)
  database.close()
}
