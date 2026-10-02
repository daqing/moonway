///|
struct ProbePost {
  id : Int
  title : String
  published : Bool
  score : Double
} derive(ToJson, FromJson, Eq, Debug)

///|
let probe_table : Table = table("probe_posts", [
  column("id", IntT, primary=true),
  column("title", TextT),
  column("published", BoolT),
  column("score", RealT),
])

///|
fn as_int(v : @sqlite.SqlValue?) -> Int? {
  match v {
    Some(@sqlite.Int(i)) => Some(i)
    _ => None
  }
}

///|
fn as_double(v : @sqlite.SqlValue?) -> Double? {
  match v {
    Some(@sqlite.Double(d)) => Some(d)
    _ => None
  }
}

///|
test "values round-trip through sqlite honoring column types" {
  let db = open(":memory:").unwrap()
  assert_true(db.exec(probe_table.create_sql()))
  let post : ProbePost = { id: 1, title: "hello", published: true, score: 4.5, }
  assert_true(db.insert(probe_table, post))
  assert_eq(db.count(probe_table), 1)
  let rows : Array[ProbePost] = db.all(probe_table)
  assert_eq(rows.length(), 1)
  assert_eq(rows[0], post)
  let found : ProbePost? = db.find(probe_table, 1)
  assert_eq(found, Some(post))
  let missing : ProbePost? = db.find(probe_table, 2)
  assert_eq(missing, None)
  let filtered : Array[ProbePost] = db.query(probe_table, "\"score\" > ?", [
    @sqlite.Double(4.0),
  ])
  assert_eq(filtered.length(), 1)
  db.close()
}

///|
test "null values stay null through the mapping" {
  assert_true(json_to_sql(Json::null(), TextT) is None)
  assert_eq(sql_to_json(@sqlite.Null, TextT).stringify(), "null")
}

///|
test "string values coerce for numeric columns" {
  assert_eq(as_int(json_to_sql(Json("7"), IntT)), Some(7))
  assert_eq(as_double(json_to_sql(Json("2.5"), RealT)), Some(2.5))
  assert_eq(as_int(json_to_sql(Json("true"), BoolT)), Some(1))
}
