<div align="center">

# moonway

**The road to the moon.**

A full-stack web framework for [MoonBit](https://www.moonbitlang.com) — routing,
database, caching, WebSocket, an auto-generated admin dashboard, and more.
Everything a modern web app needs, designed to work together from your first
`moon new`.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) · [English](README.mbt.md) | [简体中文](README.zh-CN.md)

</div>

## Why moonway?

MoonBit is fast, type-safe, and a joy to write — but assembling a real web
application today means picking a router, wiring a database client, bolting on
a cache, and writing the glue yourself. **moonway** is batteries-included: one
cohesive framework where the pieces of a modern web app are designed to fit
together, so you can go from idea to running application in minutes.

The name is the mission: **moon + way — the road to the moon.**

## Features

- **HTTP routing** — expressive routes with path parameters and a composable
  middleware pipeline.
- **Database layer** — a typed data abstraction with migrations and a fluent
  query API. SQLite works out of the box.
- **Caching** — Redis-backed caching as a drop-in middleware.
- **WebSocket** — first-class support for realtime features like chat and live
  updates.
- **Admin dashboard** — a CRUD admin UI generated from your models. Zero
  frontend work required.
- **REPL console** — an interactive console to query data and poke at your
  running app.
- **Code generator** — scaffolding for models, handlers, and more, so
  boilerplate never slows you down.
- **Frontend included** — an integrated [Preact](https://preactjs.com) workflow
  for the client side of your app.

## Quick start

Install the [MoonBit toolchain](https://docs.moonbitlang.com), then:

```bash
moon new hello-moonway
cd hello-moonway
moon add daqing/moonway
```

Give your app a route:

```moonbit nocheck
///|
fn main {
  let app = @moonway.new()
  app.get("/", ctx => ctx.text("Hello, moonway!"))
  app.listen(3000)
}
```

Run it:

```bash
moon run cmd/main
```

Open <http://localhost:3000>. You're on the road. 🌙

## The full stack, in one file

```moonbit nocheck
///|
struct Post {
  id : Int
  title : String
  body : String
}

///|
fn main {
  let app = @moonway.new()
  let db = @moonway.sqlite("app.db")
  db.migrate()

  app.get("/posts", ctx => ctx.json(db.all(Post)))

  app.post("/posts", ctx => {
    let post = ctx.bind(Post)
    db.insert(post)
    ctx.status(201).json(post)
  })

  // A ready-to-use admin UI for your data, served at /admin
  app.admin("/admin", [Post])

  app.listen(3000)
}
```

## The toolkit

### Generator

```bash
moonway generate scaffold Post title:string body:string
```

```console
created  models/post.mbt
created  handlers/posts.mbt
created  migrations/001_create_posts.mbt
updated  admin registry
```

> The `moonway` CLI ships with the framework — install it with
> `moon install daqing/moonway`.

### Admin dashboard

<!-- TODO: add a screenshot of the generated admin dashboard -->

Every registered model gets a searchable, paginated CRUD interface at
`/admin` — create, edit, and inspect your data without writing a line of
frontend code.

### REPL console

```console
$ moonway console
moonway 0.1.0 · connected to sqlite://app.db
moonway> Post.count()
42
```

## Roadmap

moonway is being built in the open for the October 2026 MoonBit hackathon
(final submission: **October 31, 2026**).

- [x] Project setup — repository, toolchain, CI
- [ ] HTTP router & middleware pipeline
- [ ] SQLite database layer & migrations
- [ ] Code generator (`moonway new`, `moonway generate`)
- [ ] Redis cache middleware
- [ ] WebSocket support
- [ ] Auto-generated admin dashboard
- [ ] REPL console
- [ ] Preact frontend integration
- [ ] Guides, examples & documentation

## Contributing

Contributions are welcome! Open an issue to talk about what you'd like to
build, or submit a pull request directly.

## License

[MIT](LICENSE) © 2026 David Zhang
