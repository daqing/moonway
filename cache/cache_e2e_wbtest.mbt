///|
async test "cache serves hits and stores misses" {
  @async.with_task_group(async fn(group) {
    let client = RedisClient::connect("127.0.0.1:6379")
    let policy : @http.CachePolicy[RedisClient] = {
      store: client,
      prefix: "moonway-test",
      ttl: 60,
    }
    let _ = client.del("moonway-test:/hello")
    group.spawn_bg(
      async fn() {
        @http.serve_cached_async(policy, 18095, _req => {
          let resp = @http.Response::new()
          resp.set_body("computed")
          resp
        }) catch {
          err => eprintln("moonway: test server failed: \{err}")
        }
      },
      no_wait=true,
    )
    let (first, body1) = @async_http.get("http://127.0.0.1:18095/hello")
    assert_eq(first.code, 200)
    assert_eq(body1.text(), "computed")
    assert_eq(first.headers.get("X-Cache"), Some("MISS"))
    let (second, body2) = @async_http.get("http://127.0.0.1:18095/hello")
    assert_eq(second.code, 200)
    assert_eq(body2.text(), "computed")
    assert_eq(second.headers.get("X-Cache"), Some("HIT"))
    client.close()
  })
}
