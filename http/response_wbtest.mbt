///|
test "reason_of maps standard status codes" {
  assert_eq(reason_of(200), "OK")
  assert_eq(reason_of(201), "Created")
  assert_eq(reason_of(204), "No Content")
  assert_eq(reason_of(301), "Moved Permanently")
  assert_eq(reason_of(404), "Not Found")
  assert_eq(reason_of(405), "Method Not Allowed")
  assert_eq(reason_of(500), "Internal Server Error")
  assert_eq(reason_of(503), "Service Unavailable")
  assert_eq(reason_of(599), "Unknown")
}
