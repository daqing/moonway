///|
test "encode_command produces bulk-string arrays" {
  assert_eq(encode_command(["PING"]), b"*1\r\n$4\r\nPING\r\n")
  assert_eq(
    encode_command(["SET", "key", "value"]),
    b"*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n",
  )
}

///|
test "encode_command counts UTF-8 byte lengths" {
  assert_eq(
    encode_command(["SET", "键", "值"]),
    b"*3\r\n$3\r\nSET\r\n$3\r\n\xe9\x94\xae\r\n$3\r\n\xe5\x80\xbc\r\n",
  )
}

///|
test "decode handles every simple reply type" {
  assert_eq(decode(b"+OK\r\n"), Complete(Simple("OK"), 5))
  assert_eq(
    decode(b"-ERR unknown command\r\n"),
    Complete(Error("ERR unknown command"), 22),
  )
  assert_eq(decode(b":1000\r\n"), Complete(Integer(1000L), 7))
  assert_eq(decode(b"$6\r\nfoobar\r\n"), Complete(Bulk(Some("foobar")), 12))
  assert_eq(decode(b"$-1\r\n"), Complete(Bulk(None), 5))
}

///|
test "decode handles arrays including nested and empty" {
  assert_eq(
    decode(b"*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n"),
    Complete(Array([Bulk(Some("foo")), Bulk(Some("bar"))]), 22),
  )
  assert_eq(decode(b"*0\r\n"), Complete(Array([]), 4))
  assert_eq(
    decode(b"*2\r\n$3\r\nfoo\r\n*1\r\n:7\r\n"),
    Complete(Array([Bulk(Some("foo")), Array([Integer(7L)])]), 21),
  )
}

///|
test "decode asks for more bytes on partial input" {
  assert_eq(decode(b"+OK"), Incomplete)
  assert_eq(decode(b"$6\r\nfoo"), Incomplete)
  assert_eq(decode(b"*2\r\n$3\r\nfoo\r\n"), Incomplete)
  assert_eq(decode(b""), Incomplete)
}

///|
test "decode reports malformed input" {
  assert_eq(decode(b"?what\r\n"), Malformed("unknown reply type 63"))
  assert_eq(decode(b"$x\r\n"), Malformed("invalid bulk length"))
  assert_eq(decode(b"*-2\r\n"), Malformed("negative array length"))
}

///|
test "decode consumes only the first reply" {
  match decode(b"+OK\r\n+AGAIN\r\n") {
    Complete(value, used) => {
      assert_eq(value, Simple("OK"))
      assert_eq(used, 5)
    }
    _ => fail("expected a complete reply")
  }
}
