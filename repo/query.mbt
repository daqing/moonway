///|
pub(all) struct Prepared {
  query : String
  args : Array[@sql.Value]
} derive(Debug, Eq)

///|
pub fn compile_named_query(
  query : String,
  values : @sql.NamedArgs,
) -> Prepared raise RepoError {
  if query == "" {
    return { query, args: [], }
  }
  let chars = query.to_array()
  let args : Array[@sql.Value] = []
  let mut output = ""
  let mut index = 0
  while index < chars.length() {
    if chars[index] == '@' &&
      index + 1 < chars.length() &&
      ident_start(chars[index + 1]) {
      let mut end = index + 2
      while end < chars.length() && ident_part(chars[end]) {
        end += 1
      }
      let name = chars[index + 1:end]
        .iter()
        .map(char => char.to_string())
        .join("")
      match values.get(name) {
        Some(value) => args.push(value)
        None => raise RepoError::MissingNamedArg(name)
      }
      output = output + "?"
      index = end
    } else {
      output = output + chars[index].to_string()
      index += 1
    }
  }
  { query: output, args, }
}

///|
fn ident_start(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || char == '_'
}

///|
fn ident_part(char : Char) -> Bool {
  ident_start(char) || (char >= '0' && char <= '9')
}

///|
pub fn prepare_query(
  driver : Driver,
  query : String,
  values : @sql.NamedArgs,
) -> Prepared raise RepoError {
  let transformed = transform_query_for_driver(driver, query)
  let prepared = compile_named_query(transformed, values)
  { ..prepared, query: driver.rebind(prepared.query), }
}

///|
pub fn[S : @sql.Stmt] prepare_builder(
  driver : Driver,
  stmt : S,
) -> Prepared raise {
  let effective = match driver {
    SQLite => stmt.without_locking()
    MySQL => stmt.without_delete_subquery()
    Postgres => stmt
  }
  let (query, values) = effective.to_sql()
  prepare_query(driver, query, values)
}

///|
pub fn[S : @sql.Stmt] prepare_insert_builder(
  driver : Driver,
  stmt : S,
) -> Prepared raise {
  let (query, values) = stmt.to_sql()
  let normalized = if driver == Driver::MySQL {
    strip_returning_clause(query)
  } else {
    query
  }
  prepare_query(driver, normalized, values)
}

///|
pub fn[S : @sql.Stmt] preview_with_driver(
  driver : Driver,
  stmt : S,
) -> Prepared raise {
  prepare_builder(driver, stmt)
}

///|
pub fn transform_query_for_driver(
  driver : Driver,
  query : String,
) -> String raise RepoError {
  match driver {
    SQLite => {
      if query.to_upper().contains(" ON CONFLICT ON CONSTRAINT ") {
        raise RepoError::UnsupportedFeature(
          "sqlite does not support ON CONFLICT ON CONSTRAINT",
        )
      }
      replace_ilike(query).trim().to_owned()
    }
    MySQL => transform_mysql_query(query)
    Postgres => query
  }
}

///|
fn replace_ilike(query : String) -> String {
  query
  .replace_all(old="NOT ILIKE", new="NOT LIKE")
  .replace_all(old="ILIKE", new="LIKE")
}

///|
fn transform_mysql_query(query : String) -> String raise RepoError {
  let upper = query.to_upper()
  if upper.contains(" ON CONFLICT ON CONSTRAINT ") {
    raise RepoError::UnsupportedFeature(
      "mysql does not support ON CONFLICT ON CONSTRAINT",
    )
  }
  if upper.contains(" RETURNING ") {
    raise RepoError::UnsupportedFeature(
      "mysql does not support RETURNING in this execution path",
    )
  }
  var_mysql_transform(replace_ilike(query).replace_all(old="\"", new="`"))
}

///|
fn var_mysql_transform(query : String) -> String {
  let upper = query.to_upper()
  if upper.contains(" ON CONFLICT") && upper.contains(" DO NOTHING") {
    let conflict_start = find_case_insensitive(query, " ON CONFLICT")
    let prefix = query[:conflict_start].to_owned()
    return prefix
      .replace_all(old="INSERT INTO", new="INSERT IGNORE INTO")
      .trim()
      .to_owned()
  }
  if upper.contains(" ON CONFLICT") && upper.contains(" DO UPDATE SET ") {
    let conflict_start = find_case_insensitive(query, " ON CONFLICT")
    let update_start = find_case_insensitive(query, " DO UPDATE SET ")
    let prefix = query[:conflict_start].to_owned()
    let values_start = update_start + " DO UPDATE SET ".length()
    let assignments = replace_excluded(query[values_start:].to_owned())
    return (prefix + " ON DUPLICATE KEY UPDATE " + assignments)
      .trim()
      .to_owned()
  }
  replace_excluded(query).trim().to_owned()
}

///|
fn find_case_insensitive(source : String, pattern : String) -> Int32 {
  match source.to_upper().find(pattern) {
    Some(index) => index
    None => source.length()
  }
}

///|
fn replace_excluded(source : String) -> String {
  let chars = source.to_array()
  let marker = "EXCLUDED.".to_array()
  let mut output = ""
  let mut index = 0
  while index < chars.length() {
    let mut matched = index + marker.length() <= chars.length()
    if matched {
      for offset in 0..<marker.length() {
        if chars[index + offset] != marker[offset] {
          matched = false
          break
        }
      }
    }
    if matched {
      let start = index + marker.length()
      let mut end = start
      while end < chars.length() && ident_part(chars[end]) {
        end += 1
      }
      if end > start {
        let name = chars[start:end]
          .iter()
          .map(char => char.to_string())
          .join("")
        output = output + "VALUES(" + name + ")"
        index = end
        continue
      }
    }
    output = output + chars[index].to_string()
    index += 1
  }
  output
}

///|
pub fn strip_returning_clause(query : String) -> String {
  let index = find_case_insensitive(query, " RETURNING ")
  if index == query.length() {
    query.trim().to_owned()
  } else {
    query[:index].trim().to_owned()
  }
}
