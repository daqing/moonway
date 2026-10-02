///|
/// `RedisClient` implements the HTTP layer's cache-store interface, so the
/// serving layer never depends on Redis directly.
pub impl @http.CacheStore for RedisClient with fn cache_get(self, key) {
  self.get(key)
}

///|
pub impl @http.CacheStore for RedisClient with fn cache_set_ex(
  self,
  key,
  value,
  ttl,
) {
  self.set_ex(key, value, ttl)
}

///|
pub extend RedisClient with @http.CacheStore::{cache_get, cache_set_ex}
