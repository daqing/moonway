///|
let render_table : @db.Table = @db.table("render_posts", [
  @db.column("id", @db.IntT, primary=true),
  @db.column("title", @db.TextT),
  @db.column("published", @db.BoolT),
  @db.column("views", @db.IntT),
])

///|
fn row_of(title : String, published : Bool, views : Int) -> Json {
  let fields : Map[String, Json] = Map([])
  fields["id"] = Json(1)
  fields["title"] = Json(title)
  fields["published"] = Json(published)
  fields["views"] = Json(views)
  Json::object(fields)
}

///|
test "escape_html escapes entities" {
  assert_eq(@admin.escape_html("<b>"), "&lt;b&gt;")
  assert_eq(@admin.escape_html("a&b"), "a&amp;b")
  assert_eq(@admin.escape_html("\"'"), "&quot;&#39;")
}

///|
test "form_decode parses url-encoded bodies" {
  let form = @admin.form_decode("title=Hi+there&body=a%26b&published=true")
  assert_eq(form.get("title"), Some("Hi there"))
  assert_eq(form.get("body"), Some("a&b"))
  assert_eq(form.get("published"), Some("true"))
  assert_eq(form.get("missing"), None)
}

///|
test "render_index links every table" {
  let page = @admin.render_index("/admin", [render_table])
  assert_true(page.contains("href=\"/admin/render_posts\""))
  assert_true(page.contains("render_posts"))
}

///|
test "render_list shows rows, actions, search and pagination" {
  let rows = [row_of("First", true, 7)]
  let page = @admin.render_list("/admin", render_table, rows, 2, true, "fir")
  assert_true(page.contains("<th>title</th>"))
  assert_true(page.contains("<td>First</td>"))
  assert_true(page.contains("value=\"fir\""))
  assert_true(page.contains("/admin/render_posts?page=1&q=fir"))
  assert_true(page.contains("/admin/render_posts?page=3&q=fir"))
  assert_true(page.contains("return confirm('Delete this row?')"))
  assert_true(page.contains("/admin/render_posts/1/edit"))
}

///|
test "render_form renders type-appropriate controls" {
  let create = @admin.render_form("/admin", render_table, None)
  assert_true(create.contains("new render_posts"))
  assert_true(create.contains("action=\"/admin/render_posts\""))
  assert_true(create.contains("<textarea name=\"title\""))
  assert_true(create.contains("type=\"number\""))
  assert_false(create.contains("checked"))
  let edit = @admin.render_form(
    "/admin",
    render_table,
    Some(row_of("Hello", true, 9)),
  )
  assert_true(edit.contains("edit render_posts"))
  assert_true(edit.contains(">Hello</textarea>"))
  assert_true(edit.contains("checked"))
  assert_true(edit.contains("value=\"9\""))
}
