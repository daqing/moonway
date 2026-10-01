///|
pub fn serve(port : Int, _handler : (Request) -> Response) -> Unit {
  println("moonway: listening on http://localhost:\{port}")
  println(
    "moonway: the HTTP/1.1 server lands in T3 (docs/TASKS.md); dispatch is testable via App::dispatch",
  )
}
