///|
pub(all) struct Identifier {
  parts : Array[String]
}

///|
pub(all) struct TableRef {
  name : Identifier
  alias : String
}

///|
pub(all) struct ColumnRef {
  qualifier : Identifier
  name : String
  alias : String
  star : Bool
}

///|
pub type TableName = TableRef

///|
pub type FieldName = ColumnRef

///|
pub fn ident(parts : Array[String]) -> Identifier {
  let normalized : Array[String] = []
  for part in parts {
    for piece in part.split(".") {
      let trimmed = piece.trim().to_owned()
      if trimmed != "" {
        normalized.push(trimmed)
      }
    }
  }
  { parts: normalized, }
}

///|
pub fn table_of(name : String) -> TableRef {
  { name: ident([name]), alias: "", }
}

///|
pub fn table_of_parts(parts : Array[String]) -> TableRef {
  { name: ident(parts), alias: "", }
}

///|
pub fn table_alias(name : String, alias : String) -> TableRef {
  table_of(name).as_alias(alias)
}

///|
pub fn ref(name : String) -> TableRef {
  table_of(name)
}

///|
pub fn ref_as(name : String, alias : String) -> TableRef {
  table_alias(name, alias)
}

///|
pub fn col(name : String) -> ColumnRef {
  let identifier = ident([name])
  if identifier.parts.length() == 0 {
    return { qualifier: ident([]), name: "", alias: "", star: false, }
  }
  let last = identifier.parts[identifier.parts.length() - 1]
  let qualifier = identifier.parts[:identifier.parts.length() - 1].to_owned()
  if last == "*" {
    { qualifier: { parts: qualifier, }, name: "", alias: "", star: true, }
  } else {
    { qualifier: { parts: qualifier, }, name: last, alias: "", star: false, }
  }
}

///|
pub fn field(name : String) -> ColumnRef {
  col(name)
}

///|
pub fn TableRef::as_alias(self : TableRef, alias : String) -> TableRef {
  { ..self, alias: alias.trim().to_owned(), }
}

///|
pub fn TableRef::field(self : TableRef, name : String) -> ColumnRef {
  let qualifier = if self.alias == "" { self.name } else { ident([self.alias]) }
  { qualifier, name: name.trim().to_owned(), alias: "", star: false, }
}

///|
pub fn TableRef::col(self : TableRef, name : String) -> ColumnRef {
  self.field(name)
}

///|
pub fn TableRef::star(self : TableRef) -> ColumnRef {
  let qualifier = if self.alias == "" { self.name } else { ident([self.alias]) }
  { qualifier, name: "", alias: "", star: true, }
}

///|
pub fn TableRef::all(self : TableRef) -> ColumnRef {
  self.star()
}

///|
pub fn TableRef::all_fields(self : TableRef) -> ColumnRef {
  self.star()
}

///|
pub fn ColumnRef::as_alias(self : ColumnRef, alias : String) -> ColumnRef {
  { ..self, alias: alias.trim().to_owned(), }
}

///|
pub fn ColumnRef::ref(self : ColumnRef) -> ColumnRef {
  { ..self, alias: "", }
}

///|
pub fn ColumnRef::without_alias(self : ColumnRef) -> ColumnRef {
  self.ref()
}

///|
pub fn ColumnRef::asc(self : ColumnRef) -> String {
  self.ref().to_string() + " ASC"
}

///|
pub fn ColumnRef::desc(self : ColumnRef) -> String {
  self.ref().to_string() + " DESC"
}

///|
pub impl ToExpr for Identifier with fn to_expr(self) {
  Expr::Static(self.to_string())
}

///|
pub impl ToExpr for TableRef with fn to_expr(self) {
  Expr::Static(self.to_string())
}

///|
pub impl ToExpr for ColumnRef with fn to_expr(self) {
  Expr::Static(self.to_string())
}

///|
pub impl Show for Identifier with fn to_string(self) {
  self.parts.map(quote_identifier).join(".")
}

///|
pub impl Show for TableRef with fn to_string(self) {
  let base = self.name.to_string()
  if self.alias == "" {
    base
  } else {
    base + " AS " + quote_identifier(self.alias)
  }
}

///|
pub impl Show for ColumnRef with fn to_string(self) {
  let mut rendered = ""
  if self.qualifier.parts.length() > 0 {
    rendered = self.qualifier.to_string() + "."
  }
  rendered = rendered +
    (if self.star { "*" } else { quote_identifier(self.name) })
  if self.alias != "" {
    rendered = rendered + " AS " + quote_identifier(self.alias)
  }
  rendered
}

///|
pub extend Identifier with ToExpr::{to_expr}

///|
pub extend TableRef with ToExpr::{to_expr}

///|
pub extend ColumnRef with ToExpr::{to_expr}

///|
pub extend Identifier with Show::{to_string}

///|
pub extend TableRef with Show::{to_string}

///|
pub extend ColumnRef with Show::{to_string}

///|
pub fn quote_identifier(name : String) -> String {
  "\"" + name.replace_all(old="\"", new="\"\"") + "\""
}

///|
pub(open) trait Table {
  fn table_name(Self) -> String
}

///|
pub fn[T : Table] table_for(table : T) -> TableRef {
  table_of(table.table_name())
}

///|
pub fn[T : Table] field_for(table : T, column : String) -> ColumnRef {
  table_for(table).field(column)
}
