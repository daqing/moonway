///|
test "plain conditions use column hints and null operators" {
  let (query, args) = @sql.eq("name", @sql.val("John")).to_sql()
  assert_eq(query, "name = @name")
  assert_eq(args["name"], @sql.Value::Text("John"))
  assert_eq(@sql.eq("deleted_at", @sql.null()).to_sql().0, "deleted_at IS NULL")
  assert_eq(
    @sql.not_eq("deleted_at", @sql.null()).to_sql().0,
    "deleted_at IS NOT NULL",
  )
}

///|
test "empty in and not in are constant predicates" {
  assert_eq(@sql.in_cond(@sql.column("id"), []).to_sql().0, "FALSE")
  assert_eq(@sql.not_in_cond(@sql.column("id"), []).to_sql().0, "TRUE")
}

///|
test "map and between conditions preserve stable args" {
  let map_cond = @sql.h_cond(
    @sql.h([("name", @sql.val("John")), ("age", @sql.val(30))]),
  )
  let (query, args) = map_cond.to_sql()
  assert_eq(query, "age = @age AND name = @name")
  assert_eq(args.length(), 2)
  let between = @sql.between(@sql.column("age"), @sql.val(18), @sql.val(30))
  assert_eq(between.to_sql().0, "age BETWEEN @age_from AND @age_to")
}
