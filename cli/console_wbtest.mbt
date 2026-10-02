///|
let console_table : @db.Table = @db.table("console_posts", [
  @db.column("id", @db.IntT, primary=true),
  @db.column("title", @db.TextT),
])

///|
test "parse_console_line recognizes the DSL and dot-commands" {
  assert_eq(parse_console_line(""), Blank)
  assert_eq(parse_console_line("   \n"), Blank)
  assert_eq(parse_console_line(".help"), DotHelp)
  assert_eq(parse_console_line(".tables"), DotTables)
  assert_eq(parse_console_line(".quit"), DotQuit)
  assert_eq(
    parse_console_line(".frobnicate"),
    Invalid("unknown dot-command .frobnicate (try .help)"),
  )
  assert_eq(parse_console_line("Post.all()"), TableAll("Post"))
  assert_eq(parse_console_line("  Post.count()  "), TableCount("Post"))
  assert_eq(parse_console_line("Post.find(42)"), TableFind("Post", 42))
  let fields : Map[String, Json] = Map([])
  fields["title"] = Json("hi")
  assert_eq(
    parse_console_line("Post.insert({\"title\": \"hi\"})"),
    TableInsert("Post", Json::object(fields)),
  )
}

///|
test "parse_console_line rejects malformed lines" {
  assert_eq(
    parse_console_line("no dot at all"),
    Invalid(
      "expected <table>.all() / .count() / .find(id) / .insert({...}) or .help",
    ),
  )
  assert_eq(
    parse_console_line("post.all()"),
    Invalid("table names start with an upper-case letter"),
  )
  assert_eq(
    parse_console_line("Post.find(abc)"),
    Invalid("find() takes an integer id"),
  )
  assert_eq(
    parse_console_line("Post.remove()"),
    Invalid("unsupported call remove()"),
  )
}

///|
test "execute_console runs the DSL against sqlite" {
  let db = @db.open(":memory:").unwrap()
  let _ = db.exec(console_table.create_sql())
  assert_eq(
    execute_console(db, TableCount("ConsolePosts"), "app.db"),
    "no table ConsolePosts",
  )
  assert_eq(execute_console(db, TableCount("console_posts"), "app.db"), "0")
  let row : Map[String, Json] = Map([])
  row["title"] = Json("first")
  let inserted = execute_console(
    db,
    TableInsert("console_posts", Json::object(row)),
    "app.db",
  )
  assert_true(inserted.has_prefix("inserted, id = "))
  assert_eq(execute_console(db, TableCount("console_posts"), "app.db"), "1")
  let all = execute_console(db, TableAll("console_posts"), "app.db")
  assert_true(all.contains("\"title\":\"first\""))
  assert_true(all.contains("(1 rows)"))
  let found = execute_console(db, TableFind("console_posts", 1), "app.db")
  assert_true(found.contains("\"title\":\"first\""))
  assert_eq(
    execute_console(db, TableFind("console_posts", 9), "app.db"),
    "not found",
  )
  assert_eq(execute_console(db, DotTables, "app.db"), "console_posts\n")
  db.close()
}

///|
test "console help mentions the connection" {
  let help = execute_console(@db.open(":memory:").unwrap(), DotHelp, "app.db")
  assert_true(help.contains("sqlite://app.db"))
  assert_true(help.contains(".quit"))
}

///|
test "parse_console_line edge cases" {
  assert_eq(
    parse_console_line("Post.find()"),
    Invalid("find() takes an integer id"),
  )
  assert_eq(
    parse_console_line("Post.insert([1, 2])"),
    Invalid("insert() takes a JSON object"),
  )
  assert_eq(
    parse_console_line("Post.insert(oops)"),
    Invalid("insert() takes a JSON object"),
  )
  assert_eq(
    parse_console_line("Post.all() extra"),
    Invalid("unsupported call all() extra"),
  )
  assert_eq(parse_console_line("\t\r\nPost.all()\r\n"), TableAll("Post"))
}

///|
test "dot-commands are case-sensitive and blank executes to nothing" {
  assert_eq(
    parse_console_line(".TABLES"),
    Invalid("unknown dot-command .TABLES (try .help)"),
  )
  assert_eq(
    parse_console_line(".Exit"),
    Invalid("unknown dot-command .Exit (try .help)"),
  )
  let db = @db.open(":memory:").unwrap()
  assert_eq(execute_console(db, Blank, "app.db"), "")
  db.close()
}
