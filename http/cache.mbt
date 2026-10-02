///|
/// Async cache storage used by the serving layer. Implemented by
/// `@cache.RedisClient`; the HTTP layer only knows this interface.
pub(open) trait CacheStore {
  async fn cache_get(Self, String) -> String?
  async fn cache_set_ex(Self, String, String, Int) -> Bool
}

///|
/// Response-cache policy for GET requests, bound to a concrete store.
pub(all) struct CachePolicy[S] {
  store : S
  prefix : String
  ttl : Int
}

///|
pub fn[S] CachePolicy::key(self : CachePolicy[S], path : String) -> String {
  self.prefix + ":" + path
}

///|
/// A cached response: the Content-Type and the body.
pub(all) struct CachedResponse {
  content_type : String
  body : String
}

///|
fn encode_payload(cached : CachedResponse) -> String {
  cached.content_type + "\n" + cached.body
}

///|
fn decode_payload(payload : String) -> CachedResponse? {
  let split = payload.split("\n").next()
  match split {
    Some(first_line) => {
      let content_type = first_line.to_owned()
      let header_len = content_type.length() + 1
      if payload.length() < header_len {
        return None
      }
      Some({ content_type, body: payload[header_len:].to_owned(), })
    }
    None => None
  }
}

///|
/// Look up a cached response; transport failures surface as raises so the
/// serving layer can degrade gracefully.
pub async fn[S : CacheStore] CachePolicy::lookup(
  self : CachePolicy[S],
  path : String,
) -> CachedResponse? {
  match self.store.cache_get(self.key(path)) {
    Some(payload) => decode_payload(payload)
    None => None
  }
}

///|
/// Store a response. Transport failures raise; the serving layer ignores
/// them (a cache write failure must not fail the request).
pub async fn[S : CacheStore] CachePolicy::store(
  self : CachePolicy[S],
  path : String,
  cached : CachedResponse,
) -> Unit {
  let _ = self.store.cache_set_ex(
    self.key(path),
    encode_payload(cached),
    self.ttl,
  )
}
