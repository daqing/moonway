///|
test "create_sql renders quoted identifiers, types and primary key" {
  let posts = @db.table("posts", [
    @db.column("id", @db.IntT, primary=true),
    @db.column("title", @db.TextT),
    @db.column("published", @db.BoolT),
    @db.column("score", @db.RealT),
  ])
  assert_eq(
    posts.create_sql(),
    "CREATE TABLE IF NOT EXISTS \"posts\" (\"id\" INTEGER PRIMARY KEY, \"title\" TEXT, \"published\" INTEGER, \"score\" REAL)",
  )
}

///|
test "table without a primary key renders plain columns" {
  let t = @db.table("logs", [@db.column("line", @db.TextT)])
  assert_eq(
    t.create_sql(),
    "CREATE TABLE IF NOT EXISTS \"logs\" (\"line\" TEXT)",
  )
}
