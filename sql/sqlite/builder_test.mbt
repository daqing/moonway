///|
test "sqlite facade delegates full join and returning" {
  let events = @sqlite.table_of("events")
  let stmt = @sqlite.select_fields([events.all_fields()])
    .from_table(events)
    .full_join_table(
      @sqlite.table_of("audit"),
      @sqlite.raw_condition("TRUE", Map([])),
    )
  assert_eq(
    stmt.to_sql().0,
    "SELECT \"events\".* FROM \"events\" FULL JOIN \"audit\" ON TRUE",
  )
  let insert = @sqlite.insert(@sqlite.h([("id", @sqlite.val(1))])).into_table(
    events,
  )
  assert_eq(
    insert.to_sql().0,
    "INSERT INTO \"events\" (id) VALUES (@id) RETURNING *",
  )
}
