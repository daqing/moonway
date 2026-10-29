///|
test "insert uses stable columns and named args" {
  let stmt = @sql.insert(
    @sql.h([("title", @sql.val("demo")), ("completed", @sql.val(true))]),
  ).into("todos")
  let (query, args) = stmt.to_sql()
  assert_eq(
    query, "INSERT INTO todos (completed, title) VALUES (@completed, @title) RETURNING *",
  )
  assert_eq(args["completed"], @sql.Value::Bool(true))
  assert_eq(args["title"], @sql.Value::Text("demo"))
}

///|
test "nested field conditions keep unique args" {
  let issues = @sql.table_of("issues")
  let stmt = @sql.select_fields([issues.all_fields()])
    .from_table(issues)
    .where_(
      @sql.all_of([
        @sql.field_eq(issues.field("status"), @sql.val("open")),
        @sql.any_of([
          @sql.field_eq(issues.field("status"), @sql.val("closed")),
          @sql.field_eq(issues.field("kind"), @sql.val("feature")),
        ]),
        @sql.not(@sql.is_null(@sql.val(issues.field("deleted_at")))),
      ]),
    )
  let (query, args) = stmt.to_sql()
  assert_eq(
    query, "SELECT \"issues\".* FROM \"issues\" WHERE (\"issues\".\"status\" = @right AND (\"issues\".\"status\" = @right_1 OR \"issues\".\"kind\" = @right_2) AND NOT (\"issues\".\"deleted_at\" IS NULL))",
  )
  assert_eq(args.length(), 3)
  assert_eq(args["right"], @sql.Value::Text("open"))
  assert_eq(args["right_1"], @sql.Value::Text("closed"))
  assert_eq(args["right_2"], @sql.Value::Text("feature"))
}

///|
test "select supports cte join having and lock" {
  let sessions = @sql.table_of("sessions")
  let users = @sql.table_alias("users", "u")
  let posts = @sql.table_alias("posts", "p")
  let active_users_ref = @sql.table_alias("active_users", "au")
  let active_users = @sql.select_fields([@sql.field("user_id")])
    .from_table(sessions)
    .where_(@sql.field_eq(@sql.field("revoked"), @sql.val(false)))
  let stmt = @sql.select_fields([users.field("id")])
    .columns(["COUNT(\"p\".\"id\") AS post_count"])
    .with_cte("active_users", active_users)
    .from_table(users)
    .join_table(
      active_users_ref,
      @sql.field_eq(
        active_users_ref.field("user_id"),
        @sql.val(users.field("id")),
      ),
    )
    .left_join_table(
      posts,
      @sql.field_eq(posts.field("user_id"), @sql.val(users.field("id"))),
    )
    .where_(@sql.field_eq(users.field("enabled"), @sql.val(true)))
    .group_by_fields([users.field("id")])
    .having(
      @sql.compare(
        @sql.func("COUNT", [@sql.val(posts.field("id"))]),
        ">",
        @sql.val(0),
      ),
    )
    .order_by(users.field("id").desc())
    .limit(20)
    .offset(40)
    .for_update()
  let (query, args) = stmt.to_sql()
  assert_eq(
    query, "WITH active_users AS (SELECT \"user_id\" FROM \"sessions\" WHERE \"revoked\" = @right) SELECT \"u\".\"id\", COUNT(\"p\".\"id\") AS post_count FROM \"users\" AS \"u\" JOIN \"active_users\" AS \"au\" ON \"au\".\"user_id\" = \"u\".\"id\" LEFT JOIN \"posts\" AS \"p\" ON \"p\".\"user_id\" = \"u\".\"id\" WHERE \"u\".\"enabled\" = @right_1 GROUP BY \"u\".\"id\" HAVING COUNT(\"p\".\"id\") > @right_2 ORDER BY \"u\".\"id\" DESC LIMIT 20 OFFSET 40 FOR UPDATE",
  )
  assert_eq(args.length(), 3)
}

///|
test "batch upsert and insert select render expressions" {
  let upsert = @sql.insert_rows([
      @sql.h([("id", @sql.val(1)), ("name", @sql.val("alpha"))]),
      @sql.h([("id", @sql.val(2)), ("name", @sql.val("beta"))]),
    ])
    .into("users")
    .on_conflict_do_update(
      ["id"],
      @sql.h([
        ("name", @sql.excluded("name")),
        ("updated_at", @sql.raw("NOW()")),
      ]),
    )
    .returning(["id", "name"])
  let (query, args) = upsert.to_sql()
  assert_eq(
    query, "INSERT INTO users (id, name) VALUES (@id, @name), (@id_1, @name_1) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW() RETURNING id, name",
  )
  assert_eq(args.length(), 4)
  let source = @sql.select_fields([@sql.field("id"), @sql.field("email")])
    .from_table(@sql.table_of("users"))
    .where_(@sql.field_eq(@sql.field("confirmed"), @sql.val(true)))
  let insert_select = @sql.insert(Map([]))
    .into_table(@sql.table_of("newsletter_subscribers"))
    .from_select(source, ["user_id", "email"])
    .on_conflict_do_nothing(["user_id"])
  assert_eq(
    insert_select.to_sql().0,
    "INSERT INTO \"newsletter_subscribers\" (user_id, email) SELECT \"id\", \"email\" FROM \"users\" WHERE \"confirmed\" = @right ON CONFLICT (user_id) DO NOTHING RETURNING *",
  )
}

///|
test "delete limit has portable and native forms" {
  let todos = @sql.table_of("todos")
  let stmt = @sql.delete_from(todos)
    .where_(@sql.field_eq(todos.field("completed"), @sql.val(true)))
    .order_by(todos.field("id").asc())
    .limit(5)
  assert_eq(
    stmt.to_sql().0,
    "DELETE FROM \"todos\" WHERE id IN (SELECT id FROM \"todos\" WHERE \"todos\".\"completed\" = @right ORDER BY \"todos\".\"id\" ASC LIMIT 5)",
  )
  assert_eq(
    stmt.without_delete_subquery().to_sql().0,
    "DELETE FROM \"todos\" WHERE \"todos\".\"completed\" = @right ORDER BY \"todos\".\"id\" ASC LIMIT 5",
  )
  assert_true(stmt.to_sql().0.contains(" IN (SELECT "))
}

///|
test "json array and lateral helpers merge nested args" {
  let users = @sql.table_alias("users", "u")
  let posts = @sql.table_alias("posts", "p")
  let latest = @sql.select_fields([posts.field("user_id"), posts.field("title")])
    .from_table(posts)
    .where_(@sql.field_eq(posts.field("user_id"), @sql.val(users.field("id"))))
    .limit(1)
  let stmt = @sql.select_fields([users.field("id")])
    .from_table(users)
    .left_join_lateral(latest, "lp", @sql.raw_condition("TRUE", Map([])))
    .where_(
      @sql.all_of([
        @sql.json_has_key(users.field("profile").to_expr(), "status"),
        @sql.compare(
          @sql.json_get_text(
            users.field("profile").to_expr(),
            @sql.val("status"),
          ),
          "=",
          @sql.val("active"),
        ),
        @sql.array_overlap(
          users.field("roles").to_expr(),
          @sql.array([@sql.val("admin"), @sql.val("editor")]),
        ),
      ]),
    )
  let (query, args) = stmt.to_sql()
  assert_eq(
    query, "SELECT \"u\".\"id\" FROM \"users\" AS \"u\" LEFT JOIN LATERAL (SELECT \"p\".\"user_id\", \"p\".\"title\" FROM \"posts\" AS \"p\" WHERE \"p\".\"user_id\" = \"u\".\"id\" LIMIT 1) AS lp ON TRUE WHERE (\"u\".\"profile\" ? @right AND \"u\".\"profile\" ->> @right_1 = @right_2 AND \"u\".\"roles\" && ARRAY[@array_0, @array_1])",
  )
  assert_eq(args.length(), 5)
}
