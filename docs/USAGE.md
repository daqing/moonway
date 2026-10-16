# moonway 使用指南

本文根据仓库当前的 README 与源码实现整理，介绍如何安装、创建、开发和运行一个
moonway 应用。API 名称、行为与示例均以当前代码（`moon.mod` 版本 `0.11.7`）为准。

> moonway 是一个**服务端框架**，运行在 MoonBit 的 **native** 后端。所有包都以
> native 为目标编译，不支持 wasm/js 后端。

---

## 目录

1. [环境准备](#1-环境准备)
2. [安装与创建项目](#2-安装与创建项目)
3. [最小示例](#3-最小示例)
4. [项目结构](#4-项目结构)
5. [路由与 Context](#5-路由与-context)
6. [中间件](#6-中间件)
7. [数据库层](#7-数据库层)
8. [Admin 管理后台](#8-admin-管理后台)
9. [Redis 响应缓存](#9-redis-响应缓存)
10. [WebSocket](#10-websocket)
11. [静态文件与前端](#11-静态文件与前端)
12. [命令行工具 CLI](#12-命令行工具-cli)
13. [构建、测试与运行](#13-构建测试与运行)
14. [完整示例](#14-完整示例)
15. [公开 API 速查](#15-公开-api-速查)
16. [常见问题与注意事项](#16-常见问题与注意事项)

---

## 1. 环境准备

1. 安装 [MoonBit 工具链](https://docs.moonbitlang.com)（`moon` 命令可用）。
2. SQLite 系统依赖：
   - **macOS**：系统自带 SQLite，无需额外安装。
   - **Ubuntu/Debian**：`sudo apt install libsqlite3-dev`。
3. （可选）Redis 服务，仅在使用响应缓存时需要。Redis 不可用时应用会以降级模式运行，
   不会启动失败。
4. （可选）若要构建 `web/` 目录下的 Preact 前端，需要 Node.js（`npm`）。

> CI（见 `.github/workflows/ci.yml`）会在 ubuntu-latest 上安装
> `libsqlite3-dev`，然后执行 `moon check` 与 `moon test`。

---

## 2. 安装与创建项目

### 方式一：`moon new` + 手动切换后端

`moon new` 默认生成 wasm 目标，使用前必须切换为 native：

```bash
moon new hello-moonway
cd hello-moonway

# 把 preferred_target = "wasm" 改成 "native"
awk '{sub(/preferred_target = "wasm"/, "preferred_target = \"native\"")} 1' \
  moon.mod > moon.mod.tmp && mv moon.mod.tmp moon.mod

moon add daqing/moonway

# 在主包里也注册依赖
printf 'import {\n  "daqing/moonway",\n}\n' >> cmd/main/moon.pkg
```

### 方式二：`moonway new`（推荐）

`moonway` CLI 随框架提供，先用 `moon install` 安装可执行文件：

```bash
moon install daqing/moonway/cmd/moonway
```

> 注意：安装路径必须指向定义可执行文件的子包 `cmd/moonway`，直接写裸模块路径
> `daqing/moonway` 会失败，因为根包是库而非可执行程序。安装后二进制名称为
> `moonway`。

然后创建项目：

```bash
moonway new hello-moonway
cd hello-moonway
moon update
moon run cmd/main
```

`moonway new` 会自动完成：

- 生成 `preferred_target = "native"` 的 `moon.mod`，并写入 moonway 依赖；
- 生成 `cmd/main`、`models`、`handlers`、`migrations`、`web`、`static` 目录；
- 生成可运行的主程序、示例前端页面，以及 SQLite 链接参数 `-lsqlite3`。

可选参数 `--dir <dir>` 指定输出父目录：`moonway new myapp --dir apps` 会在
`apps/myapp` 下生成项目。

### 方式三：在已有模块中引入

```bash
moon add daqing/moonway
```

并在使用到的包（例如 `cmd/main/moon.pkg`）中 import 需要的子包：

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

> `moon add` **不会**把 `-lsqlite3` 链接参数继承到你的包。只要用到数据库，
> 就必须在自己的 `moon.pkg` 里显式声明 `options(link: ...)`。

---

## 3. 最小示例

`cmd/main/main.mbt`：

```moonbit
///|
fn main {
  let app = @moonway.new()
  app.get("/", ctx => ctx.text("Hello, moonway!"))
  app.listen(3000)
}
```

运行并访问：

```bash
moon run cmd/main
# 打开 http://localhost:3000
```

`app.listen(port)` 默认绑定 `127.0.0.1:<port>` 并阻塞运行，直到进程被中断。
需要接受其他机器的连接时，显式使用 `app.listen(port, host="0.0.0.0")`。

---

## 4. 项目结构

`moonway new` 生成的项目大致如下：

```
hello-moonway/
├── moon.mod                      # preferred_target = "native"
├── README.mbt.md
├── cmd/
│   └── main/
│       ├── moon.pkg              # 可执行包；声明 -lsqlite3
│       └── main.mbt              # 程序入口
├── models/
│   ├── moon.pkg
│   └── models.mbt                # admin_tables() 注册表（带 marker）
├── handlers/
│   ├── moon.pkg
│   └── handlers.mbt              # register(app, db)
├── migrations/
│   ├── moon.pkg
│   └── migrations.mbt            # all() -> Array[Migration]（带 marker）
├── web/                          # Preact + esbuild（可选，需 Node.js）
│   ├── package.json
│   └── src/main.jsx
└── static/                       # 零构建的默认前端
    ├── index.html
    └── app.js
```

`moonway generate scaffold` 通过文件中的 marker 注释增量更新注册表：

| 文件 | marker 注释 |
| --- | --- |
| `models/models.mbt` | `// moonway:admin-tables` |
| `migrations/migrations.mbt` | `// moonway:migrations` |
| `cmd/main/main.mbt` | `// moonway:register-handlers` |

请勿删除这些 marker，否则脚手架无法自动追加内容。

---

## 5. 路由与 Context

### 5.1 注册路由

`App` 提供五个 HTTP 方法，签名统一为 `(path, handler)`，其中
`handler : (Context) -> Context`：

```moonbit
app.get("/posts", ctx => ctx.text("GET"))
app.post("/posts", ctx => ctx.text("POST"))
app.put("/posts/:id", ctx => ctx.text("PUT"))
app.patch("/posts/:id", ctx => ctx.text("PATCH"))
app.delete("/posts/:id", ctx => ctx.text("DELETE"))
```

### 5.2 路径参数

用 `:name` 声明路径参数，处理器中用 `ctx.param("name")` 读取（返回 `String?`）：

```moonbit
app.get("/posts/:id", ctx => {
  match ctx.param("id") {
    Some(id) => ctx.text("post " + id)
    None => ctx.status(400).text("missing id")
  }
})
```

路由匹配规则：

- 按 `/` 切分路径，比较**段数**；
- `:name` 段捕获任意一段；
- 静态段优先于 `:param`（更长/更具体的路由胜出），同等具体度按注册顺序。

### 5.3 未匹配与 405

- 路径存在但方法不匹配：返回 `405 Method Not Allowed`，并带 `Allow` 头列出可用方法。
- 路径不存在：返回 `404`，body 为 `Not Found`。
- 若配置了静态目录，未匹配的 `GET` 请求会先尝试静态文件（见第 11 节）。

### 5.4 请求信息

```moonbit
ctx.verb()                       // "GET" / "POST" ...
ctx.path()                       // 请求路径
ctx.body()                       // 请求体字符串
ctx.query_param("name")          // String?，查询字符串参数（已 URL 解码）
ctx.request_header("accept")     // String?，请求头
```

### 5.5 构造响应

所有响应构造方法都返回 `Context`，可链式调用：

```moonbit
ctx.text("plain text")           // Content-Type: text/plain; charset=utf-8
ctx.html("<h1>hi</h1>")          // Content-Type: text/html; charset=utf-8
ctx.json(value)                  // Content-Type: application/json，value: ToJson
ctx.status(201)                  // 设置状态码
ctx.header("X-Foo", "bar")       // 设置响应头
```

`ctx.json` 接受任意实现了 `ToJson` 的值，`derive(ToJson)` 的结构体可直接使用。

---

## 6. 中间件

用 `app.middleware(fn)` 注册中间件，按注册顺序在处理器之前运行，每个中间件
接收并返回同一个 `Context`：

```moonbit
app.middleware(ctx => ctx.header("X-Framework", "moonway"))
app.middleware(ctx => {
  // 可以修改请求处理结果
  ctx.header("X-Request-Id", "123")
})
```

短路：调用 `ctx.halt()` 后，后续中间件与路由处理器都会被跳过，直接返回当前响应：

```moonbit
app.middleware(ctx => {
  match ctx.request_header("Authorization") {
    Some(_) => ctx
    None => ctx.status(401).text("auth required").halt()
  }
})
```

> `halt()` 同样会阻止 404/405 回退逻辑，因此可用于全局拦截。

---

## 7. 数据库层

数据库位于 `daqing/moonway/db` 包，底层使用 `mizchi/sqlite`。表的描述（`Table` /
`Column`）是迁移和 Admin UI 的**唯一事实来源**。

### 7.1 声明表

```moonbit
///|
let posts : @db.Table = @db.table("posts", [
  @db.column("id", @db.IntT, primary=true),
  @db.column("title", @db.TextT),
  @db.column("body", @db.TextT),
  @db.column("published", @db.BoolT),
])
```

可用列类型：`IntT`、`RealT`、`TextT`、`BoolT`（`BoolT` 在 SQLite 中存为 INTEGER）。

### 7.2 打开数据库

```moonbit
let db : @db.Database = @moonway.sqlite("app.db")
```

或在 db 包中直接 `@db.open("app.db")`（返回 `Database?`）。

### 7.3 迁移

`migrate` 是**只向前**的迁移运行器：

```moonbit
let posts : @db.Table = @db.table("posts", [
  @db.column("id", @db.IntT, primary=true),
  @db.column("title", @db.TextT),
  @db.column("body", @db.TextT),
])

///|
fn main {
  let db = @moonway.sqlite("app.db")
  if !db.migrate([
    @db.migration(1, "create posts", [posts.create_sql()]),
  ]) {
    abort("migrations failed")
  }
  // ...
}
```

- 每个 `Migration` 有 `version`、`name` 和一组 SQL `statements`；
- 已应用的版本记录在 `moonway_migrations` 表中，重复运行会跳过；
- 迁移按 version 升序执行，遇到第一条失败语句即停止并返回 `false`。

`Table::create_sql()` 生成对应的 `CREATE TABLE IF NOT EXISTS ...` 语句。

### 7.4 类型化 Row API

配合 `derive(ToJson, FromJson)` 的结构体，可以零转换代码读写：

```moonbit
///|
struct Post {
  id : Int
  title : String
  body : String
} derive(ToJson, FromJson)

///|
fn demo(db : @db.Database) -> Unit {
  let post : Post = { id: 1, title: "hello", body: "moonway" }

  // 插入：字段名与列名对应
  let _ = db.insert(posts, post)

  // 查询全部
  let all : Array[Post] = db.all(posts)

  // 按主键查询
  let one : Post? = db.find(posts, 1)

  // 带 where 的查询（参数化，args 为 @sqlite.SqlValue 数组）
  let titled : Array[Post] = db.query(posts, "title = ?", [@sqlite.Text("hello")])

  // 统计
  let n = db.count(posts)
}
```

> `insert` 从值的 `ToJson` 表示中按列名取字段：没有对应列的字段被忽略，
> 没有对应字段的列绑定为 NULL。解码失败的行会被跳过。

### 7.5 原始 Row API

用于处理任意表（例如 Admin、通用工具），行是「列名 → `Json`」的 `Map`：

```moonbit
// 查询，返回 Array[Json]，支持 LIMIT/OFFSET 分页
let rows : Array[Json] = db.select_raw(posts, "1=1", [], limit=25, offset=0)

// 主键查询单行
let row : Json? = db.find_raw(posts, 1)

// 插入 / 更新 / 删除
let ok1 = db.insert_raw(posts, { "title": Json("hi"), "body": Json("...") })
let ok2 = db.update_raw(posts, 1, { "title": Json("updated") })
let ok3 = db.delete_raw(posts, 1)
```

> ⚠️ `select_raw` 的 where 子句会**原样拼接**进 SQL。切勿把未转义的用户输入直接
> 传入；需要过滤时请使用 `query` 的参数化接口，或自行转义。

### 7.6 其它

```moonbit
db.exec("VACUUM")            // 执行无返回结果的语句
db.changes()                 // 最近一次语句影响的行数
db.last_insert_rowid()       // 最近一次插入的 rowid
db.list_tables()             // 表名数组
db.table_schema("posts")     // Table?（从 SQLite 目录反查）
db.close()
```

---

## 8. Admin 管理后台

`app.admin(db, tables, ...)` 会根据表结构自动挂载一套服务端渲染的 CRUD 界面：

```moonbit
app.admin(db, [posts])
// 或指定前缀 / 访问 token
app.admin(db, [posts], prefix="/manage", token="s3cret")
```

挂载的路由（默认 `prefix = "/admin"`）：

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/admin` | 首页，列出所有表 |
| GET | `/admin/<table>` | 列表，支持 `?q=` 搜索与 `?page=` 分页（每页 25 行） |
| GET | `/admin/<table>/new` | 新建表单 |
| POST | `/admin/<table>` | 创建 |
| GET | `/admin/<table>/:id/edit` | 编辑表单 |
| POST | `/admin/<table>/:id` | 更新 |
| POST | `/admin/<table>/:id/delete` | 删除 |

特性：

- 控件类型跟随列类型：文本用 textarea、布尔用复选框、其它用数字输入；
- 文本列上的搜索使用 LIKE，并对单引号做转义；
- 写操作成功后返回 `303 See Other` 重定向回列表页。

`token` 保护（基础防护，非生产级鉴权）：token 非空时，每个请求都必须携带它——
GET 通过 `?token=...`，POST 也可通过表单字段——否则返回 `401`。

> `moonway new` 生成的 `models/models.mbt` 里有 `admin_tables()` 注册表，脚手架会
> 自动把新表追加进去。但生成的主程序默认**不会**自动挂载 admin，如需启用请在
> `cmd/main/main.mbt` 中显式调用：
>
> ```moonbit
> app.admin(db, @models.admin_tables())
> ```

---

## 9. Redis 响应缓存

缓存通过 `app.cache(client, ttl~, prefix~)` 绑定到 Redis，只缓存 `GET` 响应：

```moonbit
fn main {
  let app = @moonway.new()
  let client = @cache.RedisClient::connect("127.0.0.1:6379")
  app.cache(client, ttl=60, prefix="myapp")
  app.get("/", ctx => ctx.text("cached!"))
  app.listen(3000)
}
```

行为：

- 命中缓存的请求在中间件和处理器之前直接返回，并带 `X-Cache: HIT`；
- 未命中时正常派发，仅当响应状态为 `200` 时写入缓存（TTL 秒），并带 `X-Cache: MISS`；
- **降级**：Redis 不可用时请求照常处理，只在 stderr 打印
  `moonway: cache unavailable, serving without cache`；写缓存失败不会导致请求失败，
  此时不输出 `X-Cache` 头。

### 在 async main 中手动接线

当你使用 `async fn main`（例如需要 WebSocket，见下一节）时，不能再用 `app.listen`
的同步包装，而应直接调用 async 服务入口：

```moonbit
async fn main {
  let app = @moonway.new()
  // ... 注册路由 ...
  let handler = fn(request) { app.dispatch(request) }
  let ws_routes = app.ws_routes

  try {
    let client = @cache.RedisClient::connect("127.0.0.1:6379")
    let policy : @http.CachePolicy[@cache.RedisClient] = {
      store: client,
      prefix: "myapp",
      ttl: 60,
    }
    @http.serve_cached_async(policy, 3000, handler, ws_routes~)
  } catch {
    _err => {
      eprintln("redis not available, running without cache")
      @http.serve_async(3000, handler, ws_routes~)
    }
  }
}
```

也可以用 `app.cache(...)` 配置好缓存，再调用 `app.listen`（同步包装内部会选择
`serve_cached`）。

Redis 客户端还提供原生命令：`get` / `set` / `set_ex` / `del` / `expire` / `ping`
以及通用的 `command(args)`。

---

## 10. WebSocket

用 `app.ws(path, handler)` 注册 WebSocket 路由（精确路径匹配）。`handler` 是一个
`WsHandler`，包含两个异步回调：

```moonbit
let hub = @moonway.WsHub::new()

app.ws("/chat", {
  on_message: async fn(conn, text) {
    hub.join(conn)
    hub.broadcast("someone said: \{text}")
  },
  on_close: fn(conn) { hub.leave(conn) },
})
```

- `on_message(conn, text)`：每收到一条文本消息调用一次；
- `on_close(conn)`：连接关闭或出错时**恰好调用一次**；
- 框架负责接收循环，用户无需处理帧与握手。

`WsConn` 提供 `send_text(text)`、`recv_text()`（异步）、`close()`。

`WsHub` 是一个广播中心，适合聊天室等场景：

```moonbit
hub.join(conn)         // 加入
hub.leave(conn)        // 离开
hub.broadcast("hi")    // 异步广播给所有连接（失败的发送被静默丢弃）
```

> 由于 WebSocket 处理器是 `async` 的，使用它的应用应写成 `async fn main`，并像
> 上一节那样直接调用 `@http.serve_async` / `@http.serve_cached_async`（记得把
> `app.ws_routes` 传进去）。`app.listen` 的同步包装同样支持 ws 路由。

完整的聊天示例见 `examples/chat`。

---

## 11. 静态文件与前端

### 11.1 静态文件服务

`app.static_files(dir)` 为**未匹配的 GET 请求**提供静态文件回退：

```moonbit
app.static_files("static")
```

解析规则：

- `/` 映射到 `dir/index.html`；
- 目录映射到该目录下的 `index.html`；
- 按扩展名推断 `Content-Type`（HTML/JS/CSS/JSON/SVG/图片/字体等，未知类型为
  `application/octet-stream`）；
- 文本类型走字符串响应体，二进制（图片等）走字节响应体；
- `..` 路径穿越在访问文件系统前即被拒绝。

动态路由始终优先于静态文件。

### 11.2 前端工作流

`moonway new` 会生成两套前端：

1. **零构建版**（默认可用）：`static/index.html` + `static/app.js`，纯 vanilla
   JS，直接 fetch `/posts` API 并渲染列表/表单，无需 Node.js。
2. **Preact + esbuild 版**（可选）：`web/` 目录，构建后会覆盖 `static/app.js`。

```bash
cd web
npm install
npm run build     # esbuild src/main.jsx > ../static/app.js
```

生成的主程序默认调用 `app.static_files("static")`，因此 `/` 会返回静态首页。

---

## 12. 命令行工具 CLI

CLI 位于 `daqing/moonway/cli` 包，可执行入口为 `cmd/moonway`：

```bash
moon install daqing/moonway/cmd/moonway
```

也可以不安装、直接在仓库内运行：

```bash
moon run cmd/moonway -- --help
```

### 12.1 `moonway --help` / `--version`

```
moonway 0.11.7 — the road to the moon

Usage: moonway <command> [options]

Commands:
  moonway new <name>                          create a new moonway app
  moonway generate scaffold <Model> f:type    scaffold a model, handlers
                                              and migration
  moonway console [--db <path>]               interactive database console
  moonway --version                           print the version
  moonway --help                              print this help

Field types: string, text, int, bool, float
```

### 12.2 `moonway new <name> [--dir <dir>]`

生成一个 native、可直接运行的应用骨架（详见第 2、4 节）。若目标目录已存在则报错。

### 12.3 `moonway generate scaffold <Model> field:type ...`

在当前项目（需在项目根目录执行）生成模型、处理器与迁移，并更新注册表：

```bash
moonway generate scaffold Post title:string body:text published:bool
```

输出示例：

```console
created  models/post.mbt
created  handlers/posts.mbt
created  migrations/001_create_posts.mbt
updated  models/models.mbt, migrations/migrations.mbt, cmd/main/main.mbt
```

字段类型与生成的 MoonBit / 列类型映射：

| 脚手架 token | MoonBit 类型 | `@db.ColumnType` |
| --- | --- | --- |
| `string` / `text` | `String` | `TextT` |
| `int` | `Int` | `IntT` |
| `bool` | `Bool` | `BoolT` |
| `float` | `Double` | `RealT` |

约束与行为：

- 模型名必须以大写字母开头（否则报错）；
- 生成的模型自带 `id : Int` 主键；
- 若 `models/<snake>.mbt` 已存在则拒绝覆盖；
- 迁移版本号按 `migrations/` 下已有的 `0xx_*.mbt` 数量递增；
- 自动生成 handlers：`GET /<plural>`（列表）、`POST /<plural>`（创建，400/500 分支）、
  `GET /<plural>/:id`（详情，404 分支）。

### 12.4 `moonway console [--db <path>]`

连接项目 SQLite 数据库（默认 `app.db`）的交互式 REPL。表结构直接从 SQLite 目录
反查，无需编译进模型。

```console
$ moonway console
moonway 0.11.7 · connected to sqlite://app.db
Type .help for help, .quit to exit.
> Posts.all()
{"id":1,"title":"hello","body":"..."}
(1 rows)
> Posts.count()
1
> Posts.find(1)
{"id":1,...}
> Posts.insert({"title":"new","body":"..."})
inserted, id = 2
> .tables
posts
moonway_migrations
> .quit
```

支持的命令：

- `<Table>.all()`：打印最多 200 行 JSON，末尾附带 `(<n> rows)`；
- `<Table>.count()`：行数；
- `<Table>.find(<id>)`：按主键查询单行；
- `<Table>.insert({...})`：插入一个 JSON 对象；
- `.tables`：列出表；`.help`：帮助；`.quit` / `.exit`：退出。

大小写约定：表名首字母大写，dot 命令区分大小写。

---

## 13. 构建、测试与运行

常用命令（均在项目/仓库根目录执行）：

```bash
moon check            # 类型检查
moon test             # 运行测试
moon test --update    # 刷新快照测试
moon fmt              # 格式化（block 风格，///| 分隔）
moon info             # 更新 .mbti 生成接口
moon run cmd/main     # 运行应用，访问 http://localhost:3000
```

在本仓库中运行示例：

```bash
moon run examples/hello     # 最小示例
moon run examples/blog      # 参考应用：模型/路由/缓存/WebSocket/admin
moon run examples/chat      # WebSocket 聊天
```

开发本框架时的约定（见 `AGENTS.md`）：

- 每个包一个目录，含 `moon.pkg`；黑盒测试 `*_test.mbt`，白盒测试 `*_wbtest.mbt`；
- 推荐最后执行 `moon info && moon fmt`，并检查 `.mbti` 差异；
- 在提交前安装 git hooks（每次提交执行 `moon fmt` + `moon check` + `moon test`）：

```bash
git config core.hooksPath .githooks
```

---

## 14. 完整示例

一个包含模型、迁移、CRUD 路由与 Admin 的单文件应用（来自 README 的
"The full stack, in one file"）：

```moonbit
///|
struct Post {
  id : Int
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

  // 数据管理后台，挂在 /admin
  app.admin(db, [posts])
  app.listen(3000)
}
```

更完整的参考实现参见 `examples/blog/main.mbt`（含 Redis 缓存与 WebSocket 聊天）。

---

## 15. 公开 API 速查

### 根包 `daqing/moonway`

```moonbit
pub fn new() -> App

// App
pub fn App::get / post / put / patch / delete(Self, String, (Context) -> Context)
pub fn App::middleware(Self, (Context) -> Context)
pub fn App::static_files(Self, String)
pub fn App::cache(Self, @cache.RedisClient, ttl? : Int, prefix? : String)
pub fn App::admin(Self, @db.Database, Array[@db.Table], prefix? : String, token? : String)
pub fn App::ws(Self, String, WsHandler)
pub fn App::listen(Self, Int, host? : String)
pub fn App::dispatch(Self, @http.Request) -> @http.Response
pub fn App::handle(Self, String, String, body? : String) -> @http.Response  // 测试用

// Context
pub fn Context::halt / param / query_param / verb / path / body /
           request_header / status / header / text / html / json

// 其它
pub fn sqlite(String) -> @db.Database
pub struct WsConn { ... }   // send_text / recv_text / close
pub struct WsHandler { on_message, on_close }
pub struct WsHub { ... }    // new / join / leave / broadcast
pub async fn run_ws(WsHandler, @websocket.Conn)
```

### `daqing/moonway/db`

```moonbit
pub fn open(String) -> Database?
pub fn table(String, Array[Column]) -> Table
pub fn column(String, ColumnType, primary? : Bool) -> Column
pub fn migration(Int, String, Array[String]) -> Migration
pub fn Table::create_sql(Self) -> String

// 类型化
pub fn[T : ToJson] Database::insert(Self, Table, T) -> Bool
pub fn[T : FromJson] Database::all(Self, Table) -> Array[T]
pub fn[T : FromJson] Database::find(Self, Table, Int) -> T?
pub fn[T : FromJson] Database::query(Self, Table, String, Array[@sqlite.SqlValue]) -> Array[T]
pub fn Database::count(Self, Table) -> Int

// 原始
pub fn Database::select_raw(Self, Table, String, Array[@sqlite.SqlValue], limit? : Int, offset? : Int) -> Array[Json]
pub fn Database::find_raw(Self, Table, Int) -> Json?
pub fn Database::insert_raw(Self, Table, Map[String, Json]) -> Bool
pub fn Database::update_raw(Self, Table, Int, Map[String, Json]) -> Bool
pub fn Database::delete_raw(Self, Table, Int) -> Bool

// 迁移与维护
pub fn Database::migrate(Self, Array[Migration]) -> Bool
pub fn Database::exec / changes / last_insert_rowid / list_tables / table_schema / close
```

### `daqing/moonway/http`

```moonbit
pub fn serve(Int, (Request) -> Response, ws_routes? : Array[WsRoute], host? : String)
pub async fn serve_async(Int, (Request) -> Response, ws_routes? : Array[WsRoute], host? : String)
pub fn[S : CacheStore] serve_cached(CachePolicy[S], Int, (Request) -> Response, ws_routes? : Array[WsRoute], host? : String)
pub async fn[S : CacheStore] serve_cached_async(CachePolicy[S], Int, (Request) -> Response, ws_routes? : Array[WsRoute], host? : String)

pub struct CachePolicy[S] { store : S, prefix : String, ttl : Int }
pub struct CachedResponse { content_type : String, body : String }
pub struct Request / Response / WsRoute
```

### `daqing/moonway/cache`

```moonbit
pub async fn RedisClient::connect(String) -> RedisClient
pub async fn RedisClient::get / set / set_ex / del / expire / ping / command
pub fn RedisClient::close(Self)
// 实现 @http.CacheStore，可直接用于 CachePolicy
```

### `daqing/moonway/admin`

`render_index` / `render_list` / `render_form` / `render_layout` /
`render_unauthorized` / `form_decode` / `escape_html` / `display_value`。
通常无需直接调用，`app.admin(...)` 已封装好。

### `daqing/moonway/cli`

```moonbit
pub fn run(Array[String]) -> Unit      // CLI 入口
pub fn parse(Array[String]) -> Command
pub fn help_text() -> String
pub fn version() -> String
pub fn run_console(String) -> Unit
pub fn parse_console_line(String) -> ConsoleCommand
pub fn execute_console(@db.Database, ConsoleCommand, String) -> String
```

---

## 16. 常见问题与注意事项

1. **目标后端**：moonway 只能运行在 native 后端。用 `moon new` 创建的项目默认是
   wasm，必须手动改成 `preferred_target = "native"`；`moonway new` 生成的项目已经
   是 native。

2. **SQLite 链接参数**：`-lsqlite3` 不会从依赖继承。凡是用到数据库的包，都要在
   `moon.pkg` 里写 `options(link: { "native": { "cc-link-flags": "-lsqlite3" } })`。
   Linux 上还需安装 `libsqlite3-dev`。

3. **默认只监听本机**：`app.listen` / `serve` 默认绑定 `127.0.0.1`；需要对外监听时
   显式传入 `host="0.0.0.0"`，并自行配置相应的网络安全防护。

4. **同步 vs 异步入口**：
   - 普通应用：`fn main { app.listen(3000) }`；
   - 需要异步（WebSocket、手动缓存策略）时用 `async fn main` 并直接调用
     `@http.serve_async` / `@http.serve_cached_async`，记得传 `app.ws_routes`。

5. **Redis 可选**：没有 Redis 时请求会被正常处理（降级），但不会有缓存与 `X-Cache`
   头。

6. **迁移是只进不退的**：没有 down 迁移，重复运行会跳过已应用版本。

7. **`select_raw` 的 SQL 注入风险**：where 子句原样拼接，用户输入必须参数化或
  转义。

8. **Admin token 不是完整鉴权**：`token` 只是基础防护，生产环境请自建认证中间件。

9. **WebSocket 路由是精确匹配**，不支持 `:param`。

10. **marker 注释不可删除**：`// moonway:admin-tables`、`// moonway:migrations`、
    `// moonway:register-handlers` 被脚手架依赖，删除后 `generate scaffold` 会告警
    且不再自动更新对应文件。

---

## 参考

- [README.mbt.md](../README.mbt.md) / [README.zh-CN.md](../README.zh-CN.md) — 项目介绍与快速开始
- [docs/TASKS.md](./TASKS.md) — 开发任务看板与功能实现说明
- [AGENTS.md](../AGENTS.md) — 代码约定与工具链使用
- 示例：[examples/hello](../examples/hello)、[examples/blog](../examples/blog)、
  [examples/chat](../examples/chat)
