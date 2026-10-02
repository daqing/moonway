# moonway — Development Tasks

A step-by-step task board for building moonway incrementally, designed to be
worked through in spare time. Tasks are numbered `T<section>.<task>` (e.g.
`T1.1`, `T9.2`) and grouped to match the release milestones.

## How to use this board

1. Work roughly top-down within a milestone. Priorities tell you what to
   defend and what can slip: **P0** = the minimum viable full-stack loop,
   **P1** = core full-stack features, **P2** = nice-to-have (shrinkable — if
   cut, update the README roadmap honestly instead of dropping silently).
2. A task is **done** only when: code and tests are written, `moon test` is
   green, `moon fmt` has been applied, and the `moon info` diff (`.mbti`
   files) has been reviewed. Then tick the box.
3. Conventions: MoonBit block style (`///|` separators), deprecated code moves
   to `deprecated.mbt`, keep blocks small and focused.
4. The README is the acceptance standard: any behavior change must be
   reflected in both `README.mbt.md` and `README.zh-CN.md`.

**Legend** — M1: Oct 1–7 · M2: Oct 8–14 · M3: Oct 15–21 · M4: Oct 22–28 ·
M5: Oct 29–31 (final submission: **Oct 31, 2026**).

---

## T1 — Project foundation & CI `M1 · P0`

- [x] **T1.1** Fill in `moon.mod` metadata — description ("A full-stack web
  framework for MoonBit"), keywords; confirm `readme` still points at
  `README.mbt.md`.
- [x] **T1.2** Add GitHub Actions CI — `moon check` + `moon test` on
  ubuntu-latest (native target); add the CI badge to both READMEs.
- [x] **T1.3** Review `.githooks` — pre-commit runs `moon fmt` and `moon test`;
  document hook installation (`git config core.hooksPath .githooks`).
- [x] **T1.4** Decide the target policy for user projects — the framework runs
  on the native backend; make sure a freshly generated app compiles native on
  the first try (set `preferred_target` in generated projects, and document
  the manual step for `moon new` users in the quick start). Blocks T6.2 and
  T12.3.

## T2 — Core App & Context API (root package) `M1 · P0`

- [x] **T2.1** Define `App` — route table, middleware stack, server config;
  `@moonway.new()` constructor.
- [x] **T2.2** Define `Context` (`ctx`) — request access, path params, parsed
  body, response builders (`ctx.text()`, `ctx.json()`, `ctx.status()`).
- [x] **T2.3** `app.listen(port)` — wire `App` to the HTTP server (T3) and
  serve until interrupted.
- [x] **T2.4** Replace the scaffold test files with real unit tests for `App`
  and `Context`.
- [ ] **T2.5** `ctx.bind(Post)` — parse the request body into a model via
  FromJson (README's full-stack example uses it). Also reconcile the README
  full-stack example with the real API: `db.migrate()` takes the migrations
  array, so the example must declare its migration.

> **Done when**: the README hello-world example compiles and runs against an
> in-repo example.

## T3 — HTTP/1.1 server (http/) `M1 · P0`

Based on `moonbitlang/async@0.22.4` (decision of 2026-10-02, verified
hands-on): the runtime provides the protocol layer; moonway bridges it to the
synchronous dispatch built in T2.

- [x] **T3.1** Add the `moonbitlang/async` dependency and replace the
  `http.serve` stub with `@http.Server(...).run_forever(...)` bridged to
  `App::dispatch`.
- [x] **T3.2** Request mapping — runtime `Request` (method enum, headers,
  body reader) → moonway `Request` (`verb`, headers, body); unit tests.
- [x] **T3.3** Response mapping — moonway `Response` (status, headers, body)
  → `conn..send_response(code, reason).write(body)`; keep the Content-Type
  defaults set by the builders.
- [x] **T3.4** Error handling — handler errors surface as 500 responses
  without killing the server; document library behavior for malformed
  requests.
- [x] **T3.5** End-to-end — real serving of `examples/hello` from a plain
  `fn main` (sync bridge); verify with curl; keep-alive comes from the
  runtime.

## T4 — Router & middleware (http/) `M1 · P0`

- [x] **T4.1** Route registration — `app.get/post/put/patch/delete(path, handler)`.
  Landed with T2.1; routing now lives in `router.mbt`.
- [x] **T4.2** Path parameters — `/posts/:id` matched to `ctx.param("id")`;
  longest match wins; integration tests.
- [x] **T4.3** Middleware pipeline — `app.use(fn)`, well-defined ordering
  (linear registration order, documented on `App::use`), short-circuit
  support (`ctx.halt()`).
- [x] **T4.4** 405 responses with an `Allow` header on method mismatch.

> **Done when**: the routing part of the README "full stack in one file"
> example behaves exactly as documented.

## T5 — Database layer & SQLite (db/) `M2 · P0`

- [x] **T5.1** Model schema description — table/column mapping for MoonBit
  structs. Decision (2026-10-02, discussed): **explicit schema is the source
  of truth** — migrations and the admin UI need column types/constraints as
  data, which derives cannot provide. Row mapping rides the builtin
  `derive(ToJson, FromJson)` so simple models write zero conversion code;
  hand-written impls stay as the escape hatch for JSON-unfriendly types.
  A pure derive route is impossible today: custom derives are unsupported
  and MoonBit has no runtime reflection.
- [x] **T5.2** SQLite binding via C FFI — adopted `mizchi/sqlite@0.3.1`
  (most-used MoonBit SQLite binding, native C FFI + JS) instead of
  hand-rolling: `open` / `exec` / prepare / bind / step wrapped in the db
  package; `@moonway.sqlite(path)` opens it. Consumers using the database
  must link `-lsqlite3` (the flag is NOT inherited from dependencies —
  verified hands-on); unused imports are dead-code-eliminated and need
  nothing. CI installs libsqlite3-dev.
- [x] **T5.3** Migration runner — ordered migration files, schema version
  table; up-only migrations (keep the scope tight).
- [x] **T5.4** Query API — `db.insert`, `db.all(Model)`, `db.find(Model, id)`,
  `where` filters, `count`.
- [x] **T5.5** Tests — query API and migrations against a temporary SQLite
  database file.

> **Done when**: the database calls in the README Post example work as
> written.

## T6 — CLI & code generator (cli/) `M2 · P0`

- [x] **T6.1** `moonway` CLI skeleton — argument parsing, `--help`; the binary
  is distributed via `moon install daqing/moonway`. Lives in `cli/`
  (pure `parse` → `Command`) with a thin `cmd/moonway` wrapper reading
  `@env.args()`; `moon run cmd/moonway -- <args>` passes flags through.
- [x] **T6.2** `moonway new <name>` — generate an app skeleton: native
  `preferred_target` (per T1.4), `models/` `handlers/` `migrations/` `web/`
  folders, moonway dependency wired in. Verified hands-on: the generated app
  passes `moon check` first try and serves on :3000 with its SQLite database
  migrated (local verification maps the unpublished moonway via a
  `moon.work` members entry; published users get it from the registry).
- [x] **T6.3** `moonway generate scaffold <Model> field:type …` — model file,
  handlers (GET list/detail, POST with 400/500 paths), timestamped migration,
  and registry updates through markers (admin tables, migrations list,
  handler registration in cmd/main). Verified end-to-end: scaffolded API
  serves POST 201 / GET 200 / 404 / 400 against SQLite. Templates pin
  generic type parameters via annotated locals — leaving `db.all` to infer
  defaults the row type to Unit and silently returns `[]`.
- [x] **T6.4** File templates and generator tests (golden files). Templates
  are pure functions asserted by whitebox tests (native target, sqlite link
  flags, versioned moonway import, marker lines, pinned generic types,
  promotion extends); parsing and marker insertion are unit-tested.

> **Done when**: an app produced by `moonway new` compiles and runs on the
> first try.

## T7 — Redis cache (cache/) `M3 · P1`

- [x] **T7.1** RESP protocol encoder/decoder — pure MoonBit implementation,
  thorough unit tests. Byte-accurate bulk lengths (UTF-8 counted in bytes),
  partial-frame detection (`Incomplete`), nested arrays, and first-reply
  consumption for pipelined streams.
- [x] **T7.2** Redis client over `moonbitlang/async` TCP — `GET` / `SET` /
  `DEL` / `EXPIRE` / `PING`; server error replies surfaced as MoonBit errors.
  Live integration test against a real redis-server covers the full set
  including WRONGTYPE replies raising `Failure`.
- [x] **T7.3** Cache middleware — response caching with configurable TTL and
  cache keys. Architecture note: the linear middleware model (T4.3) has no
  post-handler phase and dispatch is synchronous while Redis is async, so
  caching attaches via `app.cache(client, ttl~, prefix~)` and lives in the
  async serving layer — http defines a `CacheStore` trait plus generic
  `CachePolicy[S]`, cache implements it for `RedisClient` (no dependency
  cycle), and `serve_cached_async` answers GET hits (`X-Cache: HIT`) before
  dispatch and stores 200s on the way out (`X-Cache: MISS`). Verified
  end-to-end against live Redis over HTTP.
- [x] **T7.4** Graceful degradation — when Redis is unreachable, requests are
  served untouched with a warning on stderr (`cache unavailable, serving
  without cache`); failed cache writes never fail the request and suppress
  the X-Cache header. Documented on the serving functions and in the README
  feature list; covered by a dead-connection end-to-end test.

## T8 — WebSocket (ws/) `M3 · P1`

Based on the `moonbitlang/async` websocket package — the handshake and RFC
6455 frames are provided by the runtime.

- [x] **T8.1** Wire the runtime websocket package into moonway's HTTP
  serving. `WsRoute` (exact-path) entries are passed to `serve`/`serve_cached_async`;
  matching GET requests are upgraded via the runtime's
  `Conn::from_http_server` (passthrough mode) and never reach dispatch.
  Verified with a live echo upgrade test using the runtime's websocket
  client.
- [x] **T8.2** `app.ws(path, handler)` — bridge websocket connections into
  moonway routing; connection events (`on_message`, `on_close`) and a
  broadcast helper. `WsConn` wraps send/recv as text, the framework runs
  the receive loop and fires `on_close` exactly once, and `WsHub` offers
  join/leave/broadcast (no locking needed inside the single-threaded event
  loop). Verified with a two-client cross-broadcast e2e test.
- [x] **T8.3** Chat example under `examples/` — `examples/chat` serves a
  minimal HTML page (native WebSocket API, no build step) plus a `/chat`
  route broadcasting through `WsHub`. Verified serving the page over HTTP;
  the WebSocket path shares the hub logic covered by T8.2's e2e test.

## T9 — Admin dashboard (admin/) `M4 · P1`

- [x] **T9.1** Model registry — `app.admin(path, [Model])` mounting.
  `app.admin(db, tables, prefix~, token~)` registers index/list/new/edit/
  update/delete routes per table; requests carry the query string
  (`Request::query_param`, previously stripped), and admin works on
  arbitrary tables through new raw row APIs
  (`select_raw`/`find_raw`/`insert_raw`/`update_raw`/`delete_raw`) — no
  concrete model types needed.
- [x] **T9.2** Server-rendered CRUD UI — paginated and searchable list,
  create/edit forms, delete with confirmation. Controls follow the schema's
  column types (textarea for text, checkbox for bools, number inputs
  otherwise); text search is a LIKE across text columns with quote
  escaping; actions are 303 redirects. Rendering is pure and unit-tested;
  the full CRUD flow is integration-tested through `app.handle`.
- [x] **T9.3** Minimal protection *(optional)* — `app.admin(..., token=...)`:
  when set, every admin request must carry the token via `?token=` (GET) or
  the form field (POST), otherwise 401. Documented on `App::admin` as basic
  protection, not production-grade auth. Covered by an integration test
  (denied, wrong token, query-allowed, POST-allowed).
- [x] **T9.4** Take the admin screenshot used by T12.4 — `docs/images/admin.png`,
  captured from a freshly scaffolded app with seeded rows (dark-mode-safe
  explicit colors in the admin layout).

## T10 — REPL console (cli/) `M4 · P2`

- [x] **T10.1** `moonway console` — loads the database connection
  (`console [--db <path>]`, default app.db) and runs an interactive
  stdin/stdout loop inside the async runtime. Tables are discovered from
  SQLite's own catalog (`list_tables`/`table_schema` via sqlite_master and
  PRAGMA table_info), so the console needs no compiled-in models.
- [x] **T10.2** Query interpreter subset — a deliberate method-call DSL,
  not a general language evaluator: `<Table>.all()` (up to 200 rows as
  JSON), `<Table>.count()`, `<Table>.find(<id>)` and
  `<Table>.insert({...})` (JSON object). Parser and executor are unit-
  tested against an in-memory database, including malformed lines.
- [x] **T10.3** Dot-commands — `.help` (connection info + command list),
  `.tables` (from the introspected schema, `(no tables)` when empty),
  `.quit`/`.exit`; blank lines are ignored, dot-commands are case-sensitive,
  and the greeting reads `moonway <version> · connected to sqlite://<path>`
  — matching the README's REPL example. Verified hands-on with a piped
  session against a seeded database.

## T11 — Preact frontend integration (preact/) `M4 · P2`

- [x] **T11.1** Frontend scaffold in generated projects — `moonway new`
  emits `static/index.html` + `static/app.js` (vanilla, zero-build, wired
  to the posts API) plus a `web/` Preact + esbuild scaffold whose
  `npm run build` regenerates `static/app.js`. Node.js prerequisite
  documented in the generated README; verified with a real
  `npm install && npm run build` (15.9 kB Preact bundle).
- [x] **T11.2** Static file serving — `app.static_files(dir)` serves
  unmatched GET requests from `dir`: `/` falls back to `index.html`,
  directories to their `index.html`, content types by extension (text
  types through the string body, binaries like images through a new bytes
  body), and `..` traversal attempts are rejected before any filesystem
  access. Dynamic routes always win. Integration-tested.
- [ ] **T11.3** Example page wired to the posts API.

> P2: shrinkable per the risk plan — if cut, remove the README feature bullet
> and say so.

## T12 — Release, example & acceptance `M3 (T12.1) · M5`

- [ ] **T12.1** Publish `daqing/moonway@0.1.0` to mooncakes.io **early (M3)** —
  verify `moon add daqing/moonway` and `moon install daqing/moonway` from a
  clean project.
- [ ] **T12.2** `examples/blog` — the reference app covering models, routes,
  cache, WebSocket chat, and admin.
- [ ] **T12.3** README acceptance run — execute every command in both READMEs
  verbatim in a clean directory; fix code or amend docs until 100% pass.
- [ ] **T12.4** README screenshots — admin dashboard (and an optional demo
  GIF); remove the `<!-- TODO -->` placeholders.
- [ ] **T12.5** Final release — version bump if needed, annotated tag,
  changelog; tick the roadmap checkboxes in both READMEs.
