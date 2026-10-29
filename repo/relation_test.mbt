///|
fn relation_users() -> @db.Table {
  @db.table("users", [
    @db.column("id", @db.IntT, primary=true),
    @db.column("name", @db.TextT),
  ])
}

///|
fn relation_posts() -> @db.Table {
  @db.table("posts", [
    @db.column("id", @db.IntT, primary=true),
    @db.column("user_id", @db.IntT),
    @db.column("title", @db.TextT),
  ])
}

///|
fn relation_database() -> (@repo.DB, @db.Table, @db.Table) raise {
  let database = @repo.new_db(":memory:")
  let users = relation_users()
  let posts = relation_posts()
  assert_true(database.raw().exec(users.create_sql()))
  assert_true(database.raw().exec(posts.create_sql()))
  for name in ["Alice", "Bob"] {
    ignore(
      @repo.insert_map(
        database,
        @sql.insert(@sql.h([("name", @sql.val(name))])).into("users"),
      ),
    )
  }
  for row in [(1, "Alice one"), (1, "Alice two"), (2, "Bob one")] {
    ignore(
      @repo.insert_map(
        database,
        @sql.insert(
          @sql.h([("user_id", @sql.val(row.0)), ("title", @sql.val(row.1))]),
        ).into("posts"),
      ),
    )
  }
  (database, users, posts)
}

///|
test "join query uses explicit relation keys" {
  let (database, users, posts) = relation_database()
  ignore(users)
  ignore(posts)
  let relation = @repo.has_many(posts, "user_id")
  let result = database
    .join(users)
    .left_joins(relation)
    .order_by("users.id ASC")
    .find()
  assert_eq(result.len(), 3)
  assert_eq(database.join(users).joins(relation).count(), 3L)
  database.close()
}

///|
test "has many preload batches related records" {
  let (database, users, posts) = relation_database()
  ignore(users)
  ignore(posts)
  let records = @repo.find_maps(
    database,
    @sql.select_fields([@sql.table_of("users").all_fields()])
    .from("users")
    .order_by("id ASC"),
  )
  database
  .preload([@repo.has_many(posts, "user_id", name="posts")])
  .exec(records)
  guard records[0]["posts"] is @sql.Value::Array(alice_posts) else {
    fail("missing Alice posts")
  }
  guard records[1]["posts"] is @sql.Value::Array(bob_posts) else {
    fail("missing Bob posts")
  }
  assert_eq(alice_posts.length(), 2)
  assert_eq(bob_posts.length(), 1)
  assert_true(
    @repo.record_to_json(records[0]).stringify().contains("Alice one"),
  )
  database.close()
}

///|
test "belongs to preload maps primary keys back to foreign keys" {
  let (database, users, posts) = relation_database()
  ignore(users)
  ignore(posts)
  let records = @repo.find_maps(
    database,
    @sql.select_fields([@sql.table_of("posts").all_fields()])
    .from("posts")
    .order_by("id ASC"),
  )
  database
  .preload([@repo.belongs_to(users, "user_id", name="author")])
  .exec(records)
  for record in records {
    guard record["author"] is @sql.Value::Object(author) else {
      fail("missing author")
    }
    match record["user_id"] {
      @sql.Value::Int(1) | @sql.Value::Int64(1L) =>
        assert_eq(author["name"], @sql.Value::Text("Alice"))
      _ => assert_eq(author["name"], @sql.Value::Text("Bob"))
    }
  }
  database.close()
}

///|
test "conditional preload combines IN and caller predicate" {
  let (database, users, posts) = relation_database()
  ignore(users)
  ignore(posts)
  let records = @repo.find_maps(
    database,
    @sql.select_fields([@sql.table_of("users").all_fields()]).from("users"),
  )
  let posts_table = @sql.table_of("posts")
  database
  .preload_cond(
    @repo.has_many(posts, "user_id", name="posts"),
    @sql.field_like(posts_table.field("title"), @sql.val("%two")),
  )
  .exec(records)
  guard records[0]["posts"] is @sql.Value::Array(alice_posts) else {
    fail("missing filtered posts")
  }
  guard records[1]["posts"] is @sql.Value::Array(bob_posts) else {
    fail("missing empty posts")
  }
  assert_eq(alice_posts.length(), 1)
  assert_eq(bob_posts.length(), 0)
  database.close()
}
