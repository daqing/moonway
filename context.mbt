///|
pub struct Context {
  request : @http.Request
  params : Map[String, String]
  response : @http.Response
}
