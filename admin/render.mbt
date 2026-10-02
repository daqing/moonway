///|
fn join_lines(lines : Array[String]) -> String {
  let mut out = ""
  for i, line in lines {
    if i > 0 {
      out = out + "\n"
    }
    out = out + line
  }
  out
}

///|
/// Wrap body content in the shared admin layout.
pub fn render_layout(title : String, body : String) -> String {
  join_lines([
    "<!doctype html>",
    "<html>",
    "<head><meta charset=\"utf-8\"><title>\{escape_html(title)} — moonway admin</title>",
    "<style>",
    "body{font-family:system-ui,sans-serif;margin:2rem;color:#111;background:#fff}",
    "table{border-collapse:collapse;width:100%}",
    "th,td{border:1px solid #ccc;padding:.4rem .6rem;text-align:left}",
    "th{background:#eef}",
    "form.inline{display:inline}",
    "a.button,button{padding:.25rem .6rem}",
    "</style>",
    "</head>",
    "<body>",
    "<h1>\{escape_html(title)}</h1>",
    body,
    "</body>",
    "</html>",
  ])
}

///|
/// The admin home page: links to every registered table.
pub fn render_index(prefix : String, tables : Array[@db.Table]) -> String {
  let items = []
  for t in tables {
    items.push(
      "<li><a href=\"\{escape_html(prefix)}/\{escape_html(t.name)}\">\{escape_html(t.name)}</a></li>",
    )
  }
  let body = join_lines(["<ul>", ..items, "</ul>"])
  render_layout("Tables", body)
}

///|
fn cell_text(row : Json, column : String) -> String {
  match row {
    Object(fields) =>
      match fields.get(column) {
        Some(value) => display_value(value)
        None => ""
      }
    _ => ""
  }
}

///|
/// The row list page: columns from the schema, one page of rows, search
/// box and pagination links.
pub fn render_list(
  prefix : String,
  t : @db.Table,
  rows : Array[Json],
  page : Int,
  has_more : Bool,
  q : String,
) -> String {
  let keep = if q == "" { "" } else { "&q=\{escape_html(q)}" }
  let head = []
  for col in t.columns {
    head.push("<th>\{escape_html(col.name)}</th>")
  }
  head.push("<th>actions</th>")
  let body_rows = []
  for row in rows {
    let cells = []
    for col in t.columns {
      cells.push("<td>\{cell_text(row, col.name)}</td>")
    }
    let id = cell_text(row, primary_name(t))
    cells.push(
      "<td><a class=\"button\" href=\"\{escape_html(prefix)}/\{escape_html(t.name)}/\{escape_html(id)}/edit\">edit</a> <form class=\"inline\" method=\"post\" action=\"\{escape_html(prefix)}/\{escape_html(t.name)}/\{escape_html(id)}/delete\" onsubmit=\"return confirm('Delete this row?')\"><button type=\"submit\">delete</button></form></td>",
    )
    body_rows.push("<tr>" + join_lines(cells) + "</tr>")
  }
  let pager = join_lines([
    "<p>",
    if page > 1 {
      "<a href=\"\{escape_html(prefix)}/\{escape_html(t.name)}?page=\{page - 1}\{keep}\">&laquo; prev</a> "
    } else {
      ""
    },
    "page \{page}",
    if has_more {
      " <a href=\"\{escape_html(prefix)}/\{escape_html(t.name)}?page=\{page + 1}\{keep}\">next &raquo;</a>"
    } else {
      ""
    },
    "</p>",
  ])
  let body = join_lines(
    [
      "<p><a href=\"\{escape_html(prefix)}\">all tables</a></p>",
      "<form method=\"get\" action=\"\{escape_html(prefix)}/\{escape_html(t.name)}\">",
      "<input name=\"q\" value=\"\{escape_html(q)}\" placeholder=\"search text columns\" />",
      "<button type=\"submit\">search</button>",
      "</form>",
      "<table><thead><tr>" + join_lines(head) + "</tr></thead><tbody>",
      ..body_rows,
      "</tbody></table>",
      pager,
      "<p><a class=\"button\" href=\"\{escape_html(prefix)}/\{escape_html(t.name)}/new\">new \{escape_html(t.name)}</a></p>",
    ],
  )
  render_layout(t.name, body)
}

///|
/// The create/edit form. `row` is None for creation; on edit the fields
/// are prefilled from the row.
pub fn render_form(prefix : String, t : @db.Table, row : Json?) -> String {
  let editing = row is Some(_)
  let title = if editing { "edit \{t.name}" } else { "new \{t.name}" }
  let action = if editing {
    let id = match row {
      Some(r) => cell_text(r, primary_name(t))
      None => ""
    }
    "\{escape_html(prefix)}/\{escape_html(t.name)}/\{escape_html(id)}"
  } else {
    "\{escape_html(prefix)}/\{escape_html(t.name)}"
  }
  let fields = []
  for col in t.columns {
    let value = match row {
      Some(r) => cell_text(r, col.name)
      None => ""
    }
    if col.primary {
      fields.push("<p>id: \{escape_html(value)}</p>")
    } else {
      match col.col_type {
        TextT =>
          fields.push(
            "<p>\{escape_html(col.name)}<br><textarea name=\"\{escape_html(col.name)}\" rows=\"4\" cols=\"60\">\{escape_html(value)}</textarea></p>",
          )
        BoolT => {
          let checked = if value == "true" || value == "1" {
            " checked"
          } else {
            ""
          }
          fields.push(
            "<p><label><input type=\"checkbox\" name=\"\{escape_html(col.name)}\" value=\"true\"\{checked}> \{escape_html(col.name)}</label></p>",
          )
        }
        _ =>
          fields.push(
            "<p>\{escape_html(col.name)}<br><input type=\"number\" step=\"any\" name=\"\{escape_html(col.name)}\" value=\"\{escape_html(value)}\"></p>",
          )
      }
    }
  }
  let body = join_lines(
    [
      "<p><a href=\"\{escape_html(prefix)}/\{escape_html(t.name)}\">back to \{escape_html(t.name)}</a></p>",
      "<form method=\"post\" action=\"\{action}\">",
      ..fields,
      "<button type=\"submit\">save</button>",
      "</form>",
    ],
  )
  render_layout(title, body)
}

///|
fn primary_name(t : @db.Table) -> String {
  for col in t.columns {
    if col.primary {
      return col.name
    }
  }
  "id"
}

///|
/// The 401 page shown when the admin token check fails.
pub fn render_unauthorized() -> String {
  render_layout("unauthorized", "<p>Invalid or missing admin token.</p>")
}
