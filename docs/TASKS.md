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
- [ ] **T4.3** Middleware pipeline — `app.use(fn)`, well-defined ordering
  (document the chosen model: registration order / onion), short-circuit
  support.
- [ ] **T4.4** 405 responses with an `Allow` header on method mismatch.

> **Done when**: the routing part of the README "full stack in one file"
> example behaves exactly as documented.

## T5 — Database layer & SQLite (db/) `M2 · P0`

- [ ] **T5.1** Model schema description — table/column mapping for MoonBit
  structs; write down the decision: derive-based vs explicit schema.
- [ ] **T5.2** SQLite binding via C FFI — open / exec / prepare / step; text,
  integer, blob, null handling. Exposed as `@moonway.sqlite(path)`.
- [ ] **T5.3** Migration runner — ordered migration files, schema version
  table; up-only migrations (keep the scope tight).
- [ ] **T5.4** Query API — `db.insert`, `db.all(Model)`, `db.find(Model, id)`,
  `where` filters, `count`.
- [ ] **T5.5** Tests — query API and migrations against a temporary SQLite
  database file.

> **Done when**: the database calls in the README Post example work as
> written.

## T6 — CLI & code generator (cli/) `M2 · P0`

- [ ] **T6.1** `moonway` CLI skeleton — argument parsing, `--help`; the binary
  is distributed via `moon install daqing/moonway`.
- [ ] **T6.2** `moonway new <name>` — generate an app skeleton: native
  `preferred_target` (per T1.4), `models/` `handlers/` `migrations/` `web/`
  folders, moonway dependency wired in.
- [ ] **T6.3** `moonway generate scaffold <Model> field:type …` — model file,
  handlers, migration, admin registration.
- [ ] **T6.4** File templates and generator tests (golden files).

> **Done when**: an app produced by `moonway new` compiles and runs on the
> first try.

## T7 — Redis cache (cache/) `M3 · P1`

- [ ] **T7.1** RESP protocol encoder/decoder — pure MoonBit implementation,
  thorough unit tests.
- [ ] **T7.2** Redis client over `moonbitlang/async` TCP — `GET` / `SET` /
  `DEL` / `EXPIRE` / `PING`; server error replies surfaced as MoonBit errors.
- [ ] **T7.3** Cache middleware — response caching with configurable TTL and
  cache keys, attached via `app.use(...)`.
- [ ] **T7.4** Graceful degradation — when Redis is unreachable, pass through
  and log a warning; document this behavior.

## T8 — WebSocket (ws/) `M3 · P1`

Based on the `moonbitlang/async` websocket package — the handshake and RFC
6455 frames are provided by the runtime.

- [ ] **T8.1** Wire the runtime websocket package into moonway's HTTP
  serving.
- [ ] **T8.2** `app.ws(path, handler)` — bridge websocket connections into
  moonway routing; connection events (`on_message`, `on_close`) and a
  broadcast helper.
- [ ] **T8.3** Chat example under `examples/`.

## T9 — Admin dashboard (admin/) `M4 · P1`

- [ ] **T9.1** Model registry — `app.admin(path, [Model])` mounting.
- [ ] **T9.2** Server-rendered CRUD UI — paginated and searchable list,
  create/edit forms, delete with confirmation.
- [ ] **T9.3** Minimal protection *(optional)* — env-token or basic auth;
  clearly documented as basic, not production-grade auth.
- [ ] **T9.4** Take the admin screenshot used by T12.4.

## T10 — REPL console (cli/) `M4 · P2`

- [ ] **T10.1** `moonway console` — loads app config and the database
  connection.
- [ ] **T10.2** Query interpreter subset — parse `<Model>.all()`,
  `<Model>.find(id)`, `<Model>.count()`, `insert`; a method-call DSL, **not**
  a general language evaluator (deliberate scope cut).
- [ ] **T10.3** Dot-commands — `.help`, `.tables`, `.quit`; prompt shows the
  connection info (`moonway 0.1.0 · connected to sqlite://app.db`).

## T11 — Preact frontend integration (preact/) `M4 · P2`

- [ ] **T11.1** Frontend scaffold in generated projects — Preact + esbuild,
  `npm run build` outputs to a static directory; document the Node.js
  prerequisite.
- [ ] **T11.2** Static file serving — content types, `index.html` fallback.
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
