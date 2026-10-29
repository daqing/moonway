///|
pub(all) enum Value {
  Null
  Int(Int32)
  Int64(Int64)
  Real(Double)
  Text(String)
  Bool(Bool)
  Blob(Bytes)
  Json(Json)
  Array(Array[Value])
  Object(Map[String, Value])
} derive(Debug, Eq)

///|
pub type NamedArgs = Map[String, Value]

///|
pub type H = Map[String, Expr]

///|
pub fn h(entries : Array[(String, Expr)]) -> H {
  Map::from_array(entries)
}

///|
pub fn named_args(entries : Array[(String, Value)]) -> NamedArgs {
  Map::from_array(entries)
}

///|
pub(open) trait ToExpr {
  fn to_expr(Self) -> Expr
}

///|
pub fn[T : ToExpr] val(value : T) -> Expr {
  value.to_expr()
}

///|
pub impl ToExpr for Value with fn to_expr(self) {
  Expr::Literal(self)
}

///|
pub impl ToExpr for Int32 with fn to_expr(self) {
  Expr::Literal(Value::Int(self))
}

///|
pub impl ToExpr for Int64 with fn to_expr(self) {
  Expr::Literal(Value::Int64(self))
}

///|
pub impl ToExpr for Double with fn to_expr(self) {
  Expr::Literal(Value::Real(self))
}

///|
pub impl ToExpr for String with fn to_expr(self) {
  Expr::Literal(Value::Text(self))
}

///|
pub impl ToExpr for Bool with fn to_expr(self) {
  Expr::Literal(Value::Bool(self))
}

///|
pub impl ToExpr for Bytes with fn to_expr(self) {
  Expr::Literal(Value::Blob(self))
}

///|
pub impl ToExpr for Json with fn to_expr(self) {
  Expr::Literal(Value::Json(self))
}

///|
pub fn null() -> Expr {
  Expr::Literal(Value::Null)
}
