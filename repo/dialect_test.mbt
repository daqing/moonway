///|
test "named args compile in occurrence order including repeats" {
  let prepared = @repo.compile_named_query(
    "a = @a OR b = @b OR c = @a",
    @sql.named_args([("a", @sql.Value::Int(1)), ("b", @sql.Value::Int(2))]),
  )
  assert_eq(prepared.query, "a = ? OR b = ? OR c = ?")
  assert_eq(prepared.args, [
    @sql.Value::Int(1),
    @sql.Value::Int(2),
    @sql.Value::Int(1),
  ])
  try @repo.compile_named_query("a = @missing", Map([])) catch {
    @repo.RepoError::MissingNamedArg("missing") => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected missing arg")
  }
}

///|
test "postgres rebind and sqlite fallback preview" {
  assert_eq(
    @repo.Driver::Postgres.rebind("a = ? AND b = ?"),
    "a = $1 AND b = $2",
  )
  let jobs = @sql.table_of("jobs")
  let locked = @sql.select_fields([jobs.all_fields()])
    .from_table(jobs)
    .where_(@sql.field_ilike(jobs.field("title"), @sql.val("%Alpha%")))
    .for_update()
  let prepared = @repo.preview_with_driver(@repo.Driver::SQLite, locked)
  assert_eq(
    prepared.query,
    "SELECT \"jobs\".* FROM \"jobs\" WHERE \"jobs\".\"title\" LIKE ?",
  )
  assert_eq(prepared.args, [@sql.Value::Text("%Alpha%")])
}

///|
test "mysql transforms delete and conflict statements" {
  let todos = @sql.table_of("todos")
  let delete = @sql.delete_from(todos)
    .order_by(todos.field("id").asc())
    .limit(1)
  assert_eq(
    @repo.preview_with_driver(@repo.Driver::MySQL, delete).query,
    "DELETE FROM `todos` ORDER BY `todos`.`id` ASC LIMIT 1",
  )
  let upsert = @sql.insert(
      @sql.h([("id", @sql.val(1)), ("name", @sql.val("alpha"))]),
    )
    .into_table(@sql.table_of("users"))
    .on_conflict_do_update(["id"], @sql.h([("name", @sql.excluded("name"))]))
  assert_eq(
    @repo.prepare_insert_builder(@repo.Driver::MySQL, upsert).query,
    "INSERT INTO `users` (id, name) VALUES (?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name)",
  )
  let ignored = @sql.insert(@sql.h([("email", @sql.val("a@example.com"))]))
    .into_table(@sql.table_of("users"))
    .on_conflict_do_nothing(["email"])
  assert_eq(
    @repo.prepare_insert_builder(@repo.Driver::MySQL, ignored).query,
    "INSERT IGNORE INTO `users` (email) VALUES (?)",
  )
}

///|
test "driver resolution normalizes sqlite and mysql dsn" {
  let sqlite = @repo.resolve_driver("", "sqlite://./tmp/test.db")
  assert_true(sqlite.0 is @repo.Driver::SQLite)
  assert_eq(sqlite.1, "./tmp/test.db")
  let mysql = @repo.resolve_driver(
    "", "mysql://root:pass@127.0.0.1:3306/airway?charset=utf8mb4",
  )
  assert_true(mysql.0 is @repo.Driver::MySQL)
  assert_eq(
    mysql.1,
    "root:pass@tcp(127.0.0.1:3306)/airway?charset=utf8mb4&parseTime=true",
  )
  let pg = @repo.resolve_driver("pgx", "postgres://localhost/app")
  assert_true(pg.0 is @repo.Driver::Postgres)
}
