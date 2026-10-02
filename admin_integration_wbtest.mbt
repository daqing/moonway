///|
let admin_test_table : @db.Table = @db.table("admin_posts", [
  @db.column("id", @db.IntT, primary=true),
  @db.column("title", @db.TextT),
  @db.column("body", @db.TextT),
  @db.column("published", @db.BoolT),
])

///|
test "admin dashboard lists, creates, searches, edits and deletes" {
  let app = new()
  let db = @db.open(":memory:").unwrap()
  let _ = db.exec(admin_test_table.create_sql())
  app.admin(db, [admin_test_table])
  assert_eq(app.handle("GET", "/admin").status(), 200)
  let created = app.handle(
    "POST",
    "/admin/admin_posts",
    body="title=Hello&body=World&published=true",
  )
  assert_eq(created.status(), 303)
  assert_eq(db.count(admin_test_table), 1)
  let list = app.handle("GET", "/admin/admin_posts")
  assert_eq(list.status(), 200)
  assert_true(list.body().contains("Hello"))
  let found = app.handle("GET", "/admin/admin_posts?q=Hello")
  assert_true(found.body().contains("Hello"))
  let missed = app.handle("GET", "/admin/admin_posts?q=zzz")
  assert_false(missed.body().contains("Hello"))
  let form = app.handle("GET", "/admin/admin_posts/1/edit")
  assert_eq(form.status(), 200)
  assert_true(form.body().contains(">Hello</textarea>"))
  let updated = app.handle(
    "POST",
    "/admin/admin_posts/1",
    body="title=Changed&body=World",
  )
  assert_eq(updated.status(), 303)
  let after = app.handle("GET", "/admin/admin_posts/1/edit")
  assert_true(after.body().contains(">Changed</textarea>"))
  assert_false(after.body().contains("checked"))
  let deleted = app.handle("POST", "/admin/admin_posts/1/delete")
  assert_eq(deleted.status(), 303)
  assert_eq(db.count(admin_test_table), 0)
  db.close()
}
