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

///|
test "admin token guard rejects requests without the token" {
  let app = new()
  let db = @db.open(":memory:").unwrap()
  let _ = db.exec(admin_test_table.create_sql())
  app.admin(db, [admin_test_table], token="s3cret")
  let denied = app.handle("GET", "/admin")
  assert_eq(denied.status(), 401)
  assert_true(denied.body().contains("Invalid or missing admin token"))
  let wrong = app.handle("GET", "/admin?token=nope")
  assert_eq(wrong.status(), 401)
  let via_query = app.handle("GET", "/admin?token=s3cret")
  assert_eq(via_query.status(), 200)
  let denied_post = app.handle(
    "POST",
    "/admin/admin_posts",
    body="title=X&body=Y",
  )
  assert_eq(denied_post.status(), 401)
  let allowed_post = app.handle(
    "POST",
    "/admin/admin_posts?token=s3cret",
    body="title=T&body=B",
  )
  assert_eq(allowed_post.status(), 303)
  db.close()
}
