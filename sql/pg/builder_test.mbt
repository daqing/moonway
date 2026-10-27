///|
test "pg facade exposes distinct locking and update from" {
  let users = @pg.table_of("users")
  let query = @pg.select_fields([users.field("id"), users.field("email")])
    .from_table(users)
    .distinct_on(["email"])
    .for_share()
  assert_eq(
    query.to_sql().0,
    "SELECT DISTINCT ON (email) \"users\".\"id\", \"users\".\"email\" FROM \"users\" FOR SHARE",
  )
  let update = @pg.update_table(users)
    .set(@pg.h([("enabled", @pg.val(false))]))
    .update_from(["sessions"])
    .where_(@pg.raw_condition("users.id = sessions.user_id", Map([])))
  assert_eq(
    update.to_sql().0,
    "UPDATE \"users\" SET enabled = @enabled FROM sessions WHERE users.id = sessions.user_id",
  )
}
