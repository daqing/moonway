///|
test "list_tables and table_schema read the sqlite catalog" {
  let db = open(":memory:").unwrap()
  let _ = db.exec(
    "CREATE TABLE alpha (id INTEGER PRIMARY KEY, title TEXT, views INT, score REAL, flag BOOLEAN)",
  )
  let _ = db.exec("CREATE TABLE beta (id INTEGER PRIMARY KEY)")
  let tables = db.list_tables()
  assert_eq(tables, ["alpha", "beta"])
  let schema = db.table_schema("alpha").unwrap()
  assert_eq(schema.name, "alpha")
  assert_eq(schema.columns.length(), 5)
  assert_true(schema.columns[0].primary)
  let types = [
    schema.columns[1].col_type,
    schema.columns[2].col_type,
    schema.columns[3].col_type,
    schema.columns[4].col_type,
  ]
  assert_eq(types, [TextT, IntT, RealT, BoolT])
  assert_true(db.table_schema("missing") is None)
  db.close()
}
