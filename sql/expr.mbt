///|
pub(all) enum Expr {
  Literal(Value)
  Raw(String, NamedArgs)
  Static(String)
  Function(String, Array[Expr])
  Binary(Expr, String, Expr)
  Wrapper(String, Expr, String)
  ArrayExpr(Array[Expr])
  SubQuery(Builder)
}

///|
pub impl ToExpr for Expr with fn to_expr(self) {
  self
}

///|
pub fn expr(sql : String) -> Expr {
  Expr::Raw(sql, Map([]))
}

///|
pub fn expr_named(sql : String, args : NamedArgs) -> Expr {
  Expr::Raw(sql, args)
}

///|
pub fn raw(sql : String) -> Expr {
  expr(sql)
}

///|
pub fn column(name : String) -> Expr {
  expr(name)
}

///|
pub fn excluded(name : String) -> Expr {
  expr("EXCLUDED." + name)
}

///|
pub fn default() -> Expr {
  expr("DEFAULT")
}

///|
pub fn func(name : String, args : Array[Expr]) -> Expr {
  Expr::Function(name, args)
}

///|
pub fn op(left : Expr, operator : String, right : Expr) -> Expr {
  Expr::Binary(left, operator, right)
}

///|
pub fn cast(value : Expr, target_type : String) -> Expr {
  Expr::Wrapper(
    "CAST(",
    Expr::Binary(value, "AS", Expr::Static(target_type)),
    ")",
  )
}

///|
pub fn array(values : Array[Expr]) -> Expr {
  Expr::ArrayExpr(values)
}

///|
pub fn any(value : Expr) -> Expr {
  Expr::Wrapper("ANY(", value, ")")
}

///|
pub fn all_expr(value : Expr) -> Expr {
  Expr::Wrapper("ALL(", value, ")")
}

///|
pub fn sub_query(query : Builder) -> Expr {
  Expr::SubQuery(query)
}

///|
priv struct BuildState {
  args : NamedArgs
  seq : Map[String, Int32]
}

///|
fn BuildState::new() -> BuildState {
  { args: Map([]), seq: Map([]), }
}

///|
fn BuildState::bind(self : BuildState, hint : String, value : Value) -> String {
  let key = self.next_key(hint)
  self.args[key] = value
  "@" + key
}

///|
fn BuildState::next_key(self : BuildState, hint : String) -> String {
  let base = sanitize_arg_name(hint)
  if !self.args.contains(base) {
    self.seq[base] = 1
    return base
  }
  let mut index = match self.seq.get(base) {
    Some(value) => value
    None => 1
  }
  while true {
    let candidate = base + "_" + index.to_string()
    if !self.args.contains(candidate) {
      self.seq[base] = index + 1
      return candidate
    }
    index += 1
  }
  abort("unreachable")
}

///|
fn BuildState::merge_expr(
  self : BuildState,
  fragment : String,
  args : NamedArgs,
) -> String {
  if fragment == "" || args.length() == 0 {
    return fragment
  }
  let mapping : Map[String, String] = Map([])
  for key in sorted_map_keys(args) {
    match args.get(key) {
      Some(value) => {
        let new_key = self.next_key(key)
        self.args[new_key] = value
        mapping[key] = new_key
      }
      None => ()
    }
  }
  replace_named_placeholders(fragment, name => {
    match mapping.get(name) {
      Some(replacement) => "@" + replacement
      None => "@" + name
    }
  })
}

///|
fn sanitize_arg_name(name : String) -> String {
  let trimmed = name.trim().to_owned()
  if trimmed == "" {
    return "p"
  }
  let mut cleaned = ""
  for char in trimmed {
    if (char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      (char >= '0' && char <= '9') ||
      char == '_' {
      cleaned = cleaned + char.to_string()
    } else {
      cleaned = cleaned + "_"
    }
  }
  cleaned = cleaned.trim(chars="_").to_owned()
  if cleaned == "" {
    return "p"
  }
  match cleaned.get_char(0) {
    Some(char) if char >= '0' && char <= '9' => "p_" + cleaned
    _ => cleaned
  }
}

///|
fn replace_named_placeholders(
  source : String,
  replacement : (String) -> String,
) -> String {
  let chars = source.to_array()
  let mut output = ""
  let mut index = 0
  while index < chars.length() {
    if chars[index] == '@' &&
      index + 1 < chars.length() &&
      is_ident_start(chars[index + 1]) {
      let mut end = index + 2
      while end < chars.length() && is_ident_part(chars[end]) {
        end += 1
      }
      let name = chars[index + 1:end]
        .iter()
        .map(char => char.to_string())
        .join("")
      output = output + replacement(name)
      index = end
    } else {
      output = output + chars[index].to_string()
      index += 1
    }
  }
  output
}

///|
fn is_ident_start(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || char == '_'
}

///|
fn is_ident_part(char : Char) -> Bool {
  is_ident_start(char) || (char >= '0' && char <= '9')
}

///|
fn render_value(
  state : BuildState,
  hint : String,
  value : Expr,
) -> String raise SqlError {
  match value {
    Literal(literal) => state.bind(hint, literal)
    Raw(sql, args) => state.merge_expr(sql, args)
    Static(sql) => sql
    Function(name, args) => {
      let parts : Array[String] = []
      for i, arg in args {
        parts.push(render_value(state, name + "_" + i.to_string(), arg))
      }
      name + "(" + parts.join(", ") + ")"
    }
    Binary(left, operator, right) =>
      render_value(state, "left", left) +
      " " +
      operator +
      " " +
      render_value(state, "right", right)
    Wrapper(prefix, inner, suffix) =>
      prefix + render_value(state, "expr", inner) + suffix
    ArrayExpr(values) => {
      let parts : Array[String] = []
      for i, item in values {
        parts.push(render_value(state, "array_" + i.to_string(), item))
      }
      "ARRAY[" + parts.join(", ") + "]"
    }
    SubQuery(query) => {
      let compiled = query.to_sql()
      "(" + state.merge_expr(compiled.0, compiled.1) + ")"
    }
  }
}

///|
fn[T] sorted_map_keys(values : Map[String, T]) -> Array[String] {
  let keys = values.keys().to_array()
  for i in 1..<keys.length() {
    let key = keys[i]
    let mut j = i
    while j > 0 && lexical_compare(keys[j - 1], key) > 0 {
      keys[j] = keys[j - 1]
      j -= 1
    }
    keys[j] = key
  }
  keys
}

///|
fn lexical_compare(left : String, right : String) -> Int32 {
  let left_chars = left.to_array()
  let right_chars = right.to_array()
  let shared = if left_chars.length() < right_chars.length() {
    left_chars.length()
  } else {
    right_chars.length()
  }
  for i in 0..<shared {
    if left_chars[i] < right_chars[i] {
      return -1
    }
    if left_chars[i] > right_chars[i] {
      return 1
    }
  }
  left_chars.length() - right_chars.length()
}

///|
fn normalize_fields(fields : Array[String]) -> Array[String] {
  let normalized : Array[String] = []
  for field in fields {
    let trimmed = field.trim().to_owned()
    if trimmed != "" {
      normalized.push(trimmed)
    }
  }
  normalized
}

///|
pub(all) suberror SqlError {
  NoValuesToInsert
  InsertColumnMismatch(row~ : Int32, column~ : String)
  NoInsertColumns
  NoValuesToUpdate
  NoConflictValues
  MissingNamedArg(String)
} derive(Debug, Eq)
