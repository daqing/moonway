///|
test "file-backed database persists across connections" {
  let path = "_build/moonway_persist_test.db"
  let db = open(path).unwrap()
  assert_true(db.exec(probe_table.create_sql()))
  assert_true(db.exec("DELETE FROM \"probe_posts\""))
  let post : ProbePost = {
    id: 7,
    title: "persisted",
    published: false,
    score: 2.25,
  }
  assert_true(db.insert(probe_table, post))
  db.close()
  let reopened = open(path).unwrap()
  let rows : Array[ProbePost] = reopened.all(probe_table)
  assert_eq(rows.length(), 1)
  assert_eq(rows[0], post)
  reopened.close()
}
