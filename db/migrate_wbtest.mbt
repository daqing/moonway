///|
let posts_table_sql : String = table("posts", [
  column("id", IntT, primary=true),
  column("title", TextT),
]).create_sql()

///|
test "migrate applies pending migrations once" {
  let db = open(":memory:").unwrap()
  let m1 = migration(1, "create posts", [posts_table_sql])
  let m2 = migration(2, "add body", [
    "ALTER TABLE \"posts\" ADD COLUMN \"body\" TEXT",
  ])
  assert_true(db.migrate([m2, m1]))
  assert_true(
    db.exec("INSERT INTO \"posts\" (id, title, body) VALUES (1, 'hi', 'there')"),
  )
  db.close()
}

///|
test "migrate is idempotent and records versions" {
  let db = open(":memory:").unwrap()
  let m1 = migration(1, "create posts", [posts_table_sql])
  assert_true(db.migrate([m1]))
  assert_true(db.migrate([m1]))
  let versions = db.applied_versions()
  assert_eq(versions.length(), 1)
  assert_eq(versions[0], 1)
  db.close()
}

///|
test "migrate stops at a failing statement" {
  let db = open(":memory:").unwrap()
  let bad = migration(1, "broken", ["THIS IS NOT SQL"])
  assert_false(db.migrate([bad]))
  db.close()
}
