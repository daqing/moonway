///|
/// A connection to a Redis server over the async runtime's TCP.
pub struct RedisClient {
  conn : @async_socket.Tcp
  mut buffer : Bytes
}

///|
/// Connect to a Redis server at `host:port` (e.g. "127.0.0.1:6379").
/// Raises when the address cannot be parsed or the connection fails.
pub async fn RedisClient::connect(addr : String) -> RedisClient {
  let parsed = @async_socket.Addr::parse(addr)
  { conn: @async_socket.Tcp::connect(parsed), buffer: b"", }
}

///|
/// Close the underlying connection.
pub fn RedisClient::close(self : RedisClient) -> Unit {
  self.conn.close()
}

///|
/// Run one command and return its reply. Redis error replies (`-ERR ...`)
/// and transport problems (connection closed, malformed reply) raise
/// `Failure`; callers decide how to degrade (see the cache middleware).
pub async fn RedisClient::command(
  self : RedisClient,
  args : Array[String],
) -> RespValue {
  self.conn.write(encode_command(args))
  while true {
    match decode(self.buffer) {
      Complete(value, used) => {
        self.buffer = self.buffer[used:].to_owned()
        match value {
          Error(message) => raise Failure::Failure(message)
          other => return other
        }
      }
      Incomplete =>
        match self.conn.read_some(max_len=8192) {
          Some(chunk) => {
            let merged : Array[Byte] = []
            for byte in self.buffer {
              merged.push(byte)
            }
            for byte in chunk {
              merged.push(byte)
            }
            self.buffer = Bytes::from_iter(merged.iter())
          }
          None => raise Failure::Failure("redis: connection closed by server")
        }
      Malformed(reason) =>
        raise Failure::Failure("redis: malformed reply: \{reason}")
    }
  } nobreak {
    abort("unreachable")
  }
}

///|
/// PING. Returns true on the expected PONG reply.
pub async fn RedisClient::ping(self : RedisClient) -> Bool {
  match self.command(["PING"]) {
    Simple("PONG") => true
    _ => raise Failure::Failure("redis: PING did not return PONG")
  }
}

///|
/// GET a string value; Bulk(None) maps to None.
pub async fn RedisClient::get(self : RedisClient, key : String) -> String? {
  match self.command(["GET", key]) {
    Bulk(value) => value
    _ => raise Failure::Failure("redis: GET returned a non-bulk reply")
  }
}

///|
/// SET a string value. Returns true on OK.
pub async fn RedisClient::set(
  self : RedisClient,
  key : String,
  value : String,
) -> Bool {
  match self.command(["SET", key, value]) {
    Simple("OK") => true
    _ => raise Failure::Failure("redis: SET did not return OK")
  }
}

///|
/// SET with an expiry in seconds.
pub async fn RedisClient::set_ex(
  self : RedisClient,
  key : String,
  value : String,
  ttl_seconds : Int,
) -> Bool {
  match self.command(["SET", key, value, "EX", "\{ttl_seconds}"]) {
    Simple("OK") => true
    _ => raise Failure::Failure("redis: SET did not return OK")
  }
}

///|
/// DEL a key; returns the number of keys removed.
pub async fn RedisClient::del(self : RedisClient, key : String) -> Int {
  match self.command(["DEL", key]) {
    Integer(n) => n.to_int()
    _ => raise Failure::Failure("redis: DEL returned a non-integer reply")
  }
}

///|
/// EXPIRE a key in seconds; false when the key does not exist.
pub async fn RedisClient::expire(
  self : RedisClient,
  key : String,
  ttl_seconds : Int,
) -> Bool {
  match self.command(["EXPIRE", key, "\{ttl_seconds}"]) {
    Integer(n) => n == 1L
    _ => raise Failure::Failure("redis: EXPIRE returned a non-integer reply")
  }
}
