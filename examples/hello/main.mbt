///|
fn main {
  let app = @moonway.new()
  app.get("/", ctx => ctx.text("Hello, moonway!"))
  app.listen(3000)
}
