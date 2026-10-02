///|
async test "client round-trips against a live redis" {
  let client = RedisClient::connect("127.0.0.1:6379")
  assert_true(client.ping())
  assert_true(client.set_ex("moonway:test:key", "value1", 60))
  assert_eq(client.get("moonway:test:key"), Some("value1"))
  assert_true(client.expire("moonway:test:key", 120))
  assert_eq(client.del("moonway:test:key"), 1)
  assert_eq(client.get("moonway:test:key"), None)
  let _ = client.set("moonway:test:strkey", "plain")
  try {
    let _ = client.command(["HINCRBY", "moonway:test:strkey", "field", "1"])
    fail("expected a WRONGTYPE error reply")
  } catch {
    _err => ()
  }
  client.close()
}
