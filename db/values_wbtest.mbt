///|
struct ProbePost {
  id : Int
  title : String
  published : Bool
  score : Double
} derive(ToJson, FromJson, Eq, Debug)

///|
extend ProbePost with ToJson::{to_json}

///|
extend ProbePost with @json.FromJson::{from_json}

///|
extend ProbePost with Eq::{equal, not_equal}

///|
extend ProbePost with @debug.Debug::{to_repr}

///|
let probe_table : Table = table("probe_posts", [
  column("id", IntT, primary=true),
  column("title", TextT),
  column("published", BoolT),
  column("score", RealT),
])

///|
fn insert_post(db : Database, post : ProbePost) -> Bool {
  let prepared = db.inner.prepare(
    "INSERT INTO probe_posts (id, title, published, score) VALUES (?, ?, ?, ?)",
  )
  match prepared {
    Some(stmt) => {
      let row_json = @json.to_json(post)
      let values : Array[@sqlite.SqlValue] = []
      for col in probe_table.columns {
        let value = match row_json {
          Object(fields) =>
            match fields.get(col.name) {
              Some(field_json) => json_to_sql(field_json, col.col_type)
              None => None
            }
          _ => None
        }
        match value {
          Some(sql_value) => values.push(sql_value)
          None => values.push(@sqlite.Null)
        }
      }
      stmt.bind_all(values) |> ignore
      let executed = stmt.execute()
      stmt.finalize()
      executed
    }
    None => false
  }
}

///|
fn decode_post(j : Json) -> ProbePost? {
  let decoded = @json.from_json(j) catch { _err => return None }
  Some(decoded)
}

///|
fn select_all_posts(db : Database) -> Array[ProbePost] {
  let posts = []
  let queried = db.inner.query(
    "SELECT id, title, published, score FROM probe_posts ORDER BY id",
  )
  match queried {
    Some(stmt) => {
      for row in stmt.iter() {
        let fields : Map[String, Json] = Map([])
        for i, col in probe_table.columns {
          fields[col.name] = sql_to_json(row.column(i), col.col_type)
        }
        match decode_post(Json::object(fields)) {
          Some(post) => posts.push(post)
          None => ()
        }
      }
      stmt.finalize()
    }
    None => ()
  }
  posts
}

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
  let post = { id: 1, title: "hello", published: true, score: 4.5, }
  assert_true(insert_post(db, post))
  assert_eq(db.changes(), 1)
  let rows = select_all_posts(db)
  assert_eq(rows.length(), 1)
  assert_eq(rows[0], post)
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
