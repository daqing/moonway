///|
test "mysql facade exposes locks and native delete limit" {
  let jobs = @mysql.table_of("jobs")
  let query = @mysql.select_fields([jobs.all_fields()])
    .from_table(jobs)
    .for_update_skip_locked()
  assert_eq(
    query.to_sql().0,
    "SELECT \"jobs\".* FROM \"jobs\" FOR UPDATE SKIP LOCKED",
  )
  let delete = @mysql.delete_from(jobs)
    .order_by(jobs.field("id").asc())
    .limit(1)
  assert_eq(
    delete.without_delete_subquery().to_sql().0,
    "DELETE FROM \"jobs\" ORDER BY \"jobs\".\"id\" ASC LIMIT 1",
  )
}
