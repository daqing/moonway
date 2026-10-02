///|
test "field tokens map to moonbit and column types" {
  assert_eq(@cli.parse_field("title:string"), Some(("title", "string")))
  assert_eq(@cli.parse_field("bad"), None)
  assert_eq(@cli.parse_field("a:b:c"), None)
  assert_eq(@cli.field_moonbit_type("float"), Some("Double"))
  assert_eq(@cli.field_moonbit_type("nope"), None)
  assert_eq(@cli.field_column_type("bool"), Some("BoolT"))
  assert_eq(@cli.field_column_type("nope"), None)
}
