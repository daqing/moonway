<div align="center">

# moonway

**The road to the moon.**

A full-stack web framework for [MoonBit](https://www.moonbitlang.com) — routing,
database, caching, WebSocket, an auto-generated admin dashboard, and more.
Everything a modern web app needs, designed to work together from your first
`moon new`.

[![CI](https://github.com/daqing/moonway/actions/workflows/ci.yml/badge.svg)](https://github.com/daqing/moonway/actions/workflows/ci.yml) · [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) · [English](README.mbt.md) | [简体中文](README.zh-CN.md)

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
- **Caching** — Redis-backed response caching with a configurable TTL
  (`app.cache(...)`); requests are served untouched when Redis is
  unavailable.
- **WebSocket** — first-class support for realtime features like chat and live
  updates.
- **Admin dashboard** — a CRUD admin UI generated from your models. Zero
  frontend work required.
- **REPL console** — an interactive console to query data and poke at your
  running app.
- **Code generator** — scaffolding for models, handlers, and more, so
  boilerplate never slows you down.
- **templ + Preact islands** — generated apps combine server-rendered
  [moon-templ](https://mooncakes.io/docs/daqing/moon-templ@0.1.0) HTML with
  hydrated [Preact](https://preactjs.com) + esbuild islands, including stateful
  components on the same page.

## Quick start

Install the [MoonBit toolchain](https://docs.moonbitlang.com), then:

```bash
moon new hello-moonway
cd hello-moonway
# moonway is a server-side framework: switch the project to the native backend
awk '{sub(/preferred_target = "wasm"/, "preferred_target = \"native\"")} 1' moon.mod > moon.mod.tmp && mv moon.mod.tmp moon.mod
moon add daqing/moonway
# register the dependency in the main package too
printf 'import {\n  "daqing/moonway",\n}\n' >> cmd/main/moon.pkg
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

`app.listen` binds to `127.0.0.1` by default. To accept connections from
other machines, explicitly use `app.listen(3000, host="0.0.0.0")`.

## The full stack, in one file

Replace `cmd/main/moon.pkg` with (the link flags are required — `moon add`
does not inherit them from dependencies; Linux also needs
`apt install libsqlite3-dev`, macOS ships SQLite):

```json
import {
  "daqing/moonway",
  "daqing/moonway/db",
  "moonbitlang/core/json",
}

supported_targets = "native"

pkgtype(kind: "executable")

options(
  link: { "native": { "cc-link-flags": "-lsqlite3" } },
)
```

Then replace `cmd/main/main.mbt` with:

```moonbit nocheck
///|
struct Post {
  id : Int32
  title : String
  body : String
} derive(ToJson, FromJson)

///|
let posts : @db.Table = @db.table("posts", [
  @db.column("id", @db.IntT, primary=true),
  @db.column("title", @db.TextT),
  @db.column("body", @db.TextT),
])

///|
fn main {
  let app = @moonway.new()
  let db = @moonway.sqlite("app.db")
  if !db.migrate([@db.migration(1, "create posts", [posts.create_sql()])]) {
    abort("migrations failed")
  }
  app.get("/posts", ctx => {
    let items : Array[Json] = db.select_raw(posts, "1=1", [], limit=100)
    ctx.json(Json::array(items))
  })
  app.post("/posts", ctx => {
    let row : Json? = Some(@json.parse(ctx.body())) catch { _err => None }
    match row {
      Some(Object(fields)) =>
        if db.insert_raw(posts, fields) {
          ctx.status(201).json(Json::object(fields))
        } else {
          ctx.status(500).text("insert failed")
        }
      _ => ctx.status(400).text("invalid JSON body")
    }
  })
  // A ready-to-use admin UI for your data, served at /admin
  app.admin(db, [posts])
  app.listen(3000)
}
```

## Generated apps: templates, islands, and Procfile

For the complete server-rendered and interactive setup, generate an app instead
of starting from the minimal `moon new` example above:

```bash
moon install daqing/moonway/cmd/moonway
moonway new hello-moonway
cd hello-moonway
moon update
```

The frontend-related files in the generated project are:

```text
hello-moonway/
├── app/
│   ├── frontend/
│   │   ├── package.json          # Preact, esbuild, and build/dev scripts
│   │   └── src/main.jsx          # Components, island registry, and hydration
│   └── templates/
│       ├── moon.pkg              # Imports the moon-templ runtime
│       ├── home.templ            # Template source: edit this file
│       ├── home_templ.mbt        # Generated MoonBit code: do not edit
│       └── pages.mbt             # Returns rendered HTML to the application
├── static/                       # Frontend build output
├── cmd/hello-moonway/main.mbt    # Homepage route and static file serving
└── Procfile                      # Development processes
```

### `app/templates`: server-rendered pages

Templates use [moon-templ](https://mooncakes.io/docs/daqing/moon-templ@0.1.0)
to render HTML on the server. Edit `home.templ`; the `moon-templ` CLI generates
`home_templ.mbt`, while `pages.mbt` exposes the rendered page as `home_page`.
The generated entry point connects the homepage and frontend assets like this:

```moonbit nocheck
app.get("/", ctx => ctx.html(@templates.home_page("hello-moonway")))
app.static_files("static")
```

The scaffold already includes `home_templ.mbt`, so the first build does not
require the template CLI. After changing a `.templ` file, put `moon-templ` on
your `PATH` and regenerate it:

```bash
moon-templ generate app/templates/home.templ
```

The `templ` process in the Procfile below automates this step during
development.

### `app/frontend` and Preact islands

`app/frontend` is a small Node.js package using [Preact](https://preactjs.com)
for stateful components and esbuild for bundling. It does not turn the whole
page into a single-page app: the server renders the page, then Preact hydrates
only the elements marked with `data-island`.

The default template provides both the island mount point and its initial
server-rendered markup:

```templ
<div data-island="counter">
  <button type="button" class="counter">Clicked 0 times</button>
</div>
<script src="/app.js"></script>
```

`app/frontend/src/main.jsx` maps island names to components and hydrates every
match. To add your own island, define a component, register it under the same
name used by the template, and make its initial render match the server HTML:

```jsx
const islands = { counter: Counter };

for (const element of document.querySelectorAll("[data-island]")) {
  const Component = islands[element.dataset.island];
  if (Component) {
    hydrate(<Component />, element);
  }
}
```

### `Procfile`: run the development processes together

The generated `Procfile` is a development process manifest:

```procfile
web: moon run cmd/hello-moonway
templ: moon-templ generate --watch app/templates/...
frontend: cd app/frontend && npm install && npm run dev
```

With `moon-templ`, Node.js, npm, and
[Foreman](https://github.com/ddollar/foreman) on your `PATH`, run this from the
project root:

```bash
foreman start
```

- `web` starts the MoonBit server.
- `templ` watches `app/templates` and regenerates MoonBit code when `.templ`
  files change.
- `frontend` installs npm dependencies and runs esbuild in watch mode, updating
  `static/app.js` whenever the frontend source changes.

You can also build and run everything manually without a Procfile runner:

```bash
cd app/frontend
npm install
npm run build
cd ../..
moon run cmd/hello-moonway
```

`npm run build` writes `static/app.js`, which `app.static_files("static")`
serves as `/app.js`; this generated bundle is ignored by Git. After a manual
build, rerun `npm run build` when frontend files change. Without the bundle,
the server-rendered HTML still works, but `/app.js` returns 404 and the islands
are not interactive.

## The toolkit

### Generator

```bash
moonway generate scaffold Post title:string body:string
```

```console
created  app/models/post.mbt
created  handlers/posts.mbt
created  migrations/001_create_posts.mbt
updated  admin registry
```

### Admin dashboard

![Admin dashboard](docs/images/admin.png)

Every registered model gets a searchable, paginated CRUD interface at
`/admin` — create, edit, and inspect your data without writing a line of
frontend code.

### REPL console

```console
$ moonway console
moonway 0.11.7 · connected to sqlite://app.db
> Posts.count()
42
```

## Roadmap

moonway is being built in the open for the October 2026 MoonBit hackathon
(final submission: **October 31, 2026**).

- [x] Project setup — repository, toolchain, CI
- [x] HTTP router & middleware pipeline
- [x] SQLite database layer & migrations
- [x] Code generator (`moonway new`, `moonway generate`)
- [x] Redis cache middleware
- [x] WebSocket support
- [x] Auto-generated admin dashboard
- [x] REPL console
- [x] Preact frontend integration
- [x] Guides, examples & documentation

## Contributing

Contributions are welcome! Open an issue to talk about what you'd like to
build, or submit a pull request directly.

Before committing, install the git hooks (formatting and tests run on every
commit):

```bash
git config core.hooksPath .githooks
```

## License

[MIT](LICENSE) © 2026 David Zhang
