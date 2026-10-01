<div align="center">

# moonway

**通往月球之路。**

基于 [MoonBit](https://www.moonbitlang.com) 的全栈 Web 开发框架——路由、数据库、
缓存、WebSocket、自动生成的 admin 管理后台，一应俱全。现代 Web 应用需要的组件，
从你第一次 `moon new` 起就为彼此设计、协同工作。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) · [English](README.mbt.md) | [简体中文](README.zh-CN.md)

</div>

## 为什么选择 moonway？

MoonBit 快、类型安全，写起来也舒服——但今天想搭一个真正的 Web 应用，你还是得自己
挑路由库、接数据库客户端、装缓存、写一堆粘合代码。**moonway** 主打「电池全含」：
一个框架把现代 Web 应用的各个组成部分整合成浑然一体，从想法到跑起来的应用只要几分钟。

名字即使命：**moon + way，通往月球之路。**

## 功能特性

- **HTTP 路由** —— 表达力强的路由定义，支持路径参数与可组合的中间件管线。
- **数据库层** —— 带迁移和流畅查询 API 的类型化数据抽象，SQLite 开箱即用。
- **缓存** —— 基于 Redis 的缓存，以中间件方式一键接入。
- **WebSocket** —— 一等公民支持，聊天、实时更新等场景信手拈来。
- **Admin 管理后台** —— 根据数据模型自动生成的 CRUD 管理界面，零前端工作量。
- **REPL 控制台** —— 交互式终端，查询数据、调试运行中的应用。
- **代码生成器** —— 为模型、处理器等生成脚手架代码，告别重复劳动。
- **前端集成** —— 内置 [Preact](https://preactjs.com) 工作流，客户端开发同样就绪。

## 快速开始

安装 [MoonBit 工具链](https://docs.moonbitlang.com)，然后：

```bash
moon new hello-moonway
cd hello-moonway
moon add daqing/moonway
```

给你的应用加一条路由：

```moonbit nocheck
///|
fn main {
  let app = @moonway.new()
  app.get("/", ctx => ctx.text("Hello, moonway!"))
  app.listen(3000)
}
```

运行：

```bash
moon run cmd/main
```

打开 <http://localhost:3000>。月球之路，就此启程。🌙

## 一个文件里的全栈

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

  // 一个开箱即用的数据管理界面，挂在 /admin
  app.admin("/admin", [Post])

  app.listen(3000)
}
```

## 工具箱

### 代码生成器

```bash
moonway generate scaffold Post title:string body:string
```

```console
created  models/post.mbt
created  handlers/posts.mbt
created  migrations/001_create_posts.mbt
updated  admin registry
```

> `moonway` CLI 随框架一起提供——通过 `moon install daqing/moonway` 安装。

### Admin 管理后台

<!-- TODO: 补充 admin 后台截图 -->

每个注册的数据模型都会在 `/admin` 下获得一个支持搜索、分页的 CRUD 管理界面——
增删改查数据，一行前端代码都不用写。

### REPL 控制台

```console
$ moonway console
moonway 0.1.0 · connected to sqlite://app.db
moonway> Post.count()
42
```

## 路线图

moonway 正在为 2026 年 10 月的 MoonBit 黑客松公开开发（最终提交：**2026 年 10 月 31 日**）。

- [x] 项目初始化——仓库、工具链、CI
- [ ] HTTP 路由与中间件管线
- [ ] SQLite 数据库层与迁移
- [ ] 代码生成器（`moonway new`、`moonway generate`）
- [ ] Redis 缓存中间件
- [ ] WebSocket 支持
- [ ] 自动生成的 Admin 管理后台
- [ ] REPL 控制台
- [ ] Preact 前端集成
- [ ] 指南、示例与文档

## 参与贡献

欢迎贡献！先开一个 issue 聊聊你想做什么，也可以直接提交 pull request。

## 许可证

[MIT](LICENSE) © 2026 David Zhang
