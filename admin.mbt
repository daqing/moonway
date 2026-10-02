///|
/// Internal configuration for the admin dashboard; captured by the route
/// handlers mounted in `App::admin`.
priv struct AdminConfig {
  db : @db.Database
  tables : Array[@db.Table]
  prefix : String
  token : String
}

///|
/// Mount the admin dashboard at `prefix` (default `/admin`) for `tables`,
/// reading and writing through `db`. When `token~` is non-empty, every
/// admin request must carry it as `?token=...` (or the hidden form field
/// on POSTs) — basic protection, not production-grade auth.
pub fn App::admin(
  self : App,
  db : @db.Database,
  tables : Array[@db.Table],
  prefix? : String = "/admin",
  token? : String = "",
) -> Unit {
  let config : AdminConfig = { db, tables, prefix, token, }
  self.get(prefix, admin_index_handler(config))
  for t in tables {
    self.get(prefix + "/" + t.name, admin_list_handler(config, t))
    self.get(prefix + "/" + t.name + "/new", admin_form_handler(config, t))
    self.post(prefix + "/" + t.name, admin_create_handler(config, t))
    self.get(prefix + "/" + t.name + "/:id/edit", admin_edit_handler(config, t))
    self.post(prefix + "/" + t.name + "/:id", admin_update_handler(config, t))
    self.post(
      prefix + "/" + t.name + "/:id/delete",
      admin_delete_handler(config, t),
    )
  }
}

///|
fn admin_index_handler(config : AdminConfig) -> (Context) -> Context {
  fn(ctx) {
    if !admin_authorized(config, ctx, admin_form(ctx)) {
      return admin_unauthorized(ctx)
    }
    ctx.html(@admin.render_index(config.prefix, config.tables))
  }
}

///|
fn admin_list_handler(
  config : AdminConfig,
  t : @db.Table,
) -> (Context) -> Context {
  fn(ctx) {
    if !admin_authorized(config, ctx, admin_form(ctx)) {
      return admin_unauthorized(ctx)
    }
    let q = ctx.query_param("q").unwrap_or("")
    let page = admin_page_number(ctx)
    let page_size = 25
    let rows = config.db.select_raw(
      t,
      admin_search_where(t, q),
      [],
      limit=page_size,
      offset=(page - 1) * page_size,
    )
    let has_more = rows.length() == page_size
    ctx.html(@admin.render_list(config.prefix, t, rows, page, has_more, q))
  }
}

///|
fn admin_form_handler(
  config : AdminConfig,
  t : @db.Table,
) -> (Context) -> Context {
  fn(ctx) {
    if !admin_authorized(config, ctx, admin_form(ctx)) {
      return admin_unauthorized(ctx)
    }
    ctx.html(@admin.render_form(config.prefix, t, None))
  }
}

///|
fn admin_edit_handler(
  config : AdminConfig,
  t : @db.Table,
) -> (Context) -> Context {
  fn(ctx) {
    if !admin_authorized(config, ctx, admin_form(ctx)) {
      return admin_unauthorized(ctx)
    }
    match admin_parse_id(ctx) {
      Some(id) =>
        match config.db.find_raw(t, id) {
          Some(row) => ctx.html(@admin.render_form(config.prefix, t, Some(row)))
          None => {
            let ctx = ctx.status(404)
            ctx.text("Not Found")
          }
        }
      None => ctx.status(400).text("invalid id")
    }
  }
}

///|
fn admin_create_handler(
  config : AdminConfig,
  t : @db.Table,
) -> (Context) -> Context {
  fn(ctx) {
    let form = @admin.form_decode(ctx.body())
    if !admin_authorized(config, ctx, form) {
      return admin_unauthorized(ctx)
    }
    if config.db.insert_raw(t, admin_row_from_form(t, form, false)) {
      admin_see_other(ctx, config.prefix + "/" + t.name)
    } else {
      ctx.status(500).text("insert failed")
    }
  }
}

///|
fn admin_update_handler(
  config : AdminConfig,
  t : @db.Table,
) -> (Context) -> Context {
  fn(ctx) {
    let form = @admin.form_decode(ctx.body())
    if !admin_authorized(config, ctx, form) {
      return admin_unauthorized(ctx)
    }
    match admin_parse_id(ctx) {
      Some(id) =>
        if config.db.update_raw(t, id, admin_row_from_form(t, form, true)) {
          admin_see_other(ctx, config.prefix + "/" + t.name)
        } else {
          ctx.status(500).text("update failed")
        }
      None => ctx.status(400).text("invalid id")
    }
  }
}

///|
fn admin_delete_handler(
  config : AdminConfig,
  t : @db.Table,
) -> (Context) -> Context {
  fn(ctx) {
    let form = @admin.form_decode(ctx.body())
    if !admin_authorized(config, ctx, form) {
      return admin_unauthorized(ctx)
    }
    match admin_parse_id(ctx) {
      Some(id) => {
        let _ = config.db.delete_raw(t, id)
        admin_see_other(ctx, config.prefix + "/" + t.name)
      }
      None => ctx.status(400).text("invalid id")
    }
  }
}

///|
fn admin_row_from_form(
  t : @db.Table,
  form : Map[String, String],
  editing : Bool,
) -> Map[String, Json] {
  let row : Map[String, Json] = Map([])
  for col in t.columns {
    if col.primary {
      continue
    }
    match form.get(col.name) {
      Some(value) => row[col.name] = Json(value)
      None =>
        match col.col_type {
          BoolT => row[col.name] = Json(false)
          _ => if editing { row[col.name] = Json("") } else { () }
        }
    }
  }
  row
}

///|
/// Basic token check: an empty token disables the guard. GET requests
/// present the token via ?token=; POSTs may also use a form field.
fn admin_authorized(
  config : AdminConfig,
  ctx : Context,
  form : Map[String, String],
) -> Bool {
  if config.token == "" {
    return true
  }
  ctx.query_param("token") == Some(config.token) ||
  form.get("token") == Some(config.token)
}

///|
fn admin_unauthorized(ctx : Context) -> Context {
  ctx.status(401).html(@admin.render_unauthorized())
}

///|
fn admin_see_other(ctx : Context, location : String) -> Context {
  let ctx = ctx.status(303)
  let ctx = ctx.header("Location", location)
  ctx.text("")
}

///|
fn admin_page_number(ctx : Context) -> Int {
  match ctx.query_param("page") {
    Some(raw) =>
      match admin_parse_int(raw) {
        Some(n) => if n < 1 { 1 } else { n }
        None => 1
      }
    None => 1
  }
}

///|
fn admin_parse_id(ctx : Context) -> Int? {
  match ctx.param("id") {
    Some(raw) => admin_parse_int(raw)
    None => None
  }
}

///|
fn admin_parse_int(raw : String) -> Int? {
  let mut value = 0
  let mut negative = false
  let mut digits = 0
  for ch in raw {
    if ch == '-' && digits == 0 && !negative {
      negative = true
    } else if ch >= '0' && ch <= '9' {
      value = value * 10 + ch.to_int() - 48
      digits = digits + 1
    } else {
      return None
    }
  }
  if digits == 0 {
    return None
  }
  Some(if negative { -value } else { value })
}

///|
/// WHERE clause filtering text columns with LIKE, or "1=1" when the query
/// is empty. Single quotes in the query are doubled.
fn admin_search_where(t : @db.Table, q : String) -> String {
  if q == "" {
    return "1=1"
  }
  let escaped = admin_double_quotes(q)
  let clauses = []
  for col in t.columns {
    if col.col_type is TextT {
      clauses.push(admin_quote_ident(col.name) + " LIKE '%" + escaped + "%'")
    }
  }
  if clauses.length() == 0 {
    return "1=1"
  }
  let mut where_clause = ""
  for i, clause in clauses {
    if i > 0 {
      where_clause = where_clause + " OR "
    }
    where_clause = where_clause + clause
  }
  where_clause
}

///|
fn admin_quote_ident(name : String) -> String {
  "\"" + admin_double_quotes(name) + "\""
}

///|
fn admin_double_quotes(s : String) -> String {
  let mut out = ""
  for ch in s {
    if ch == '\'' {
      out = out + "''"
    } else {
      out = out + ch.to_string()
    }
  }
  out
}

///|
fn admin_form(ctx : Context) -> Map[String, String] {
  @admin.form_decode(ctx.body())
}
