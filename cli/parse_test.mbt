///|
test "parse dispatches commands" {
  assert_eq(@cli.parse(["moonway"]), Help)
  assert_eq(@cli.parse(["moonway", "--help"]), Help)
  assert_eq(@cli.parse(["moonway", "-h"]), Help)
  assert_eq(@cli.parse(["moonway", "help"]), Help)
  assert_eq(@cli.parse(["moonway", "--version"]), Version)
  assert_eq(@cli.parse(["moonway", "new", "blog"]), New("blog", None))
  assert_eq(
    @cli.parse(["moonway", "new", "blog", "--dir", "tmp"]),
    New("blog", Some("tmp")),
  )
  assert_eq(
    @cli.parse(["moonway", "generate", "scaffold", "Post", "title:string"]),
    GenerateScaffold("Post", ["title:string"]),
  )
}

///|
test "parse reports usage problems" {
  assert_eq(
    @cli.parse(["moonway", "new"]),
    Invalid("usage: moonway new <name> [--dir <dir>]"),
  )
  assert_eq(
    @cli.parse(["moonway", "generate"]),
    Invalid("usage: moonway generate scaffold <Model> [field:type ...]"),
  )
  assert_eq(
    @cli.parse(["moonway", "generate", "scaffold"]),
    Invalid("usage: moonway generate scaffold <Model> [field:type ...]"),
  )
  assert_eq(
    @cli.parse(["moonway", "frobnicate"]),
    Invalid("unknown command: frobnicate (try moonway --help)"),
  )
}

///|
test "help text mentions every command" {
  let help = @cli.help_text()
  assert_true(help.contains("moonway new"))
  assert_true(help.contains("generate scaffold"))
  assert_true(help.contains("--version"))
}
