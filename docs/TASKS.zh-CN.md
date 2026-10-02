# moonway — 开发任务清单

一份可以逐步推进、适合利用闲余时间完成的 moonway 开发任务看板。任务按
`T<分区>.<序号>` 编号（如 `T1.1`、`T9.2`），分组与发布里程碑对应。

## 使用说明

1. 大致按里程碑自上而下推进。优先级说明哪些必须保住、哪些可以让路：
   **P0** = 最小可用的全栈闭环，**P1** = 全栈核心功能，**P2** = 锦上添花
   （可收缩——若收缩，必须如实更新 README 路线图，不许静默砍掉）。
2. 一个任务只有满足以下条件才算**完成**：代码与测试已写、`moon test` 全绿、
   已执行 `moon fmt`、已检查 `moon info` 产出的 `.mbti` 接口 diff。然后勾选复选框。
3. 约定：MoonBit 块状风格（`///|` 分隔），废弃代码移入 `deprecated.mbt`，
   保持小块、职责单一。
4. README 即验收标准：任何行为变化都必须同步反映到 `README.mbt.md` 与
   `README.zh-CN.md` 两份文档。

**图例** — M1：10 月 1–7 日 · M2：10 月 8–14 日 · M3：10 月 15–21 日 ·
M4：10 月 22–28 日 · M5：10 月 29–31 日（最终提交：**2026 年 10 月 31 日**）。

---

## T1 — 项目基建与 CI `M1 · P0`

- [x] **T1.1** 补全 `moon.mod` 元信息——description（"A full-stack web
  framework for MoonBit"）、keywords；确认 `readme` 仍指向 `README.mbt.md`。
- [x] **T1.2** 添加 GitHub Actions CI——ubuntu-latest 上跑 `moon check` +
  `moon test`（native target）；两份 README 加 CI 徽章。
- [x] **T1.3** 检查 `.githooks`——pre-commit 执行 `moon fmt` 和 `moon test`；
  文档写明钩子安装方式（`git config core.hooksPath .githooks`）。
- [x] **T1.4** 确定用户项目的 target 策略——框架运行在 native 后端；确保
  新生成的项目第一次编译就能通过（生成的项目里设置 `preferred_target`，
  并在快速开始文档中写明 `moon new` 用户需要的手动步骤）。阻塞 T6.2 与
  T12.3。

## T2 — 核心 App 与 Context API（根包） `M1 · P0`

- [x] **T2.1** 定义 `App`——路由表、中间件栈、服务器配置；提供
  `@moonway.new()` 构造函数。
- [x] **T2.2** 定义 `Context`（`ctx`）——请求访问、路径参数、解析后的请求体、
  响应构造器（`ctx.text()`、`ctx.json()`、`ctx.status()`）。
- [x] **T2.3** `app.listen(port)`——把 `App` 接到 HTTP 服务器（T3）上，
  持续服务直到中断。
- [x] **T2.4** 用真实的 `App` / `Context` 单元测试替换脚手架测试文件。
- [ ] **T2.5** `ctx.bind(Post)`——通过 FromJson 把请求体解析成模型（README
  全栈示例用到了）。同时把 README 全栈示例与真实 API 对齐：`db.migrate()`
  接收迁移数组，示例需要声明自己的 migration。

> **完成标准**：README 的 hello-world 示例能在仓库内示例上编译并运行。

## T3 — HTTP/1.1 服务器（http/） `M1 · P0`

基于 `moonbitlang/async@0.22.4`（2026-10-02 决策，已实测验证）：协议层由运行时
提供，moonway 把它桥接到 T2 构建的同步 dispatch 上。

- [x] **T3.1** 添加 `moonbitlang/async` 依赖，把 `http.serve` 桩替换为
  `@http.Server(...).run_forever(...)`，桥接到 `App::dispatch`。
- [x] **T3.2** 请求映射——运行时 `Request`（method 枚举、请求头、body
  reader）→ moonway `Request`（`verb`、headers、body）；单元测试。
- [x] **T3.3** 响应映射——moonway `Response`（status、headers、body）→
  `conn..send_response(code, reason).write(body)`；保留构造器设置的
  Content-Type 默认值。
- [x] **T3.4** 错误处理——handler 出错时以 500 响应返回且不拖垮服务器；
  文档写明运行时对格式非法请求的处理行为。
- [x] **T3.5** 端到端——从普通 `fn main`（同步桥接）真实启动
  `examples/hello`，用 curl 验证；keep-alive 由运行时提供。

## T4 — 路由与中间件（http/） `M1 · P0`

- [x] **T4.1** 路由注册——`app.get/post/put/patch/delete(path, handler)`。
  随 T2.1 落地；路由逻辑现集中在 `router.mbt`。
- [x] **T4.2** 路径参数——`/posts/:id` 映射到 `ctx.param("id")`；最长匹配
  优先；集成测试。
- [x] **T4.3** 中间件管线——`app.use(fn)`，明确的执行顺序（线性注册顺序，
  已在 `App::use` 文档注明），支持短路（`ctx.halt()`）。
- [x] **T4.4** 方法不匹配时返回 405 并带 `Allow` 头。

> **完成标准**：README「一个文件里的全栈」示例的路由部分与文档行为完全一致。

## T5 — 数据库层与 SQLite（db/） `M2 · P0`

- [x] **T5.1** 模型 schema 描述——MoonBit 结构体到表/列的映射。决策
  （2026-10-02，经讨论）：**显式 schema 作为唯一事实来源**——迁移和 admin
  界面需要把列类型/约束当数据用，derive 给不了。行映射借用内置
  `derive(ToJson, FromJson)`，简单模型零转换代码；JSON 表示不了的类型走
  手写 impl 逃生舱。纯 derive 路线当前不可行：自定义 derive 不受支持，
  MoonBit 也没有运行时反射。
- [x] **T5.2** SQLite 绑定——采用 `mizchi/sqlite@0.3.1`（生态中下载量最大的
  MoonBit SQLite 绑定，native C FFI + JS），不自研：open / exec / prepare /
  bind / step 由 db 包封装；`@moonway.sqlite(path)` 打开数据库。实际使用
  数据库的消费者必须自行链接 `-lsqlite3`（该参数不会从依赖继承——已实测）；
  未使用的导入会被死代码消除，无需任何配置。CI 安装 libsqlite3-dev。
- [x] **T5.3** 迁移执行器——有序迁移文件、schema 版本表；只做 up 迁移
  （控制范围）。
- [x] **T5.4** 查询 API——`db.insert`、`db.all(Model)`、`db.find(Model, id)`、
  `where` 过滤、`count`。
- [x] **T5.5** 测试——对临时 SQLite 数据库文件跑查询 API 与迁移测试。

> **完成标准**：README Post 示例中的数据库调用与文档行为一致。

## T6 — CLI 与代码生成器（cli/） `M2 · P0`

- [x] **T6.1** `moonway` CLI 骨架——参数解析、`--help`；二进制通过
  `moon install daqing/moonway` 分发。解析逻辑在 `cli/` 包（纯函数
  `parse` → `Command`），`cmd/moonway` 是读 `@env.args()` 的薄入口；
  `moon run cmd/moonway -- <args>` 透传参数。
- [x] **T6.2** `moonway new <name>`——生成应用骨架：native `preferred_target`
  （按 T1.4 的决策）、`models/` `handlers/` `migrations/` `web/` 目录、
  预先接好 moonway 依赖。已实测：生成的项目第一次 `moon check` 即通过，
  运行即在 :3000 提供服务且 SQLite 已迁移（moonway 未发布前的本地验证用
  `moon.work` members 映射；发布后的用户从 registry 拉取）。
- [x] **T6.3** `moonway generate scaffold <Model> field:type …`——生成模型
  文件、handlers（GET 列表/详情、POST 含 400/500 路径）、带时间戳版本的
  migration，并通过标记行更新各注册表（admin 表清单、迁移清单、cmd/main
  的 handler 注册）。已端到端验证：scaffold 出的 API 对 SQLite 提供
  POST 201 / GET 200 / 404 / 400。模板用注解局部变量钉住泛型类型参数——
  让 `db.all` 自行推断会把行类型默认成 Unit 并静默返回 `[]`。
- [x] **T6.4** 文件模板与生成器测试（golden 文件对比）。模板是纯函数，由
  白盒测试断言内容（native target、sqlite 链接参数、版本化 moonway 导入、
  标记行、钉住的泛型类型、promotion extends）；参数解析与标记插入有单元测试。

> **完成标准**：`moonway new` 产出的应用第一次编译、运行即成功。

## T7 — Redis 缓存（cache/） `M3 · P1`

- [x] **T7.1** RESP 协议编码器/解码器——纯 MoonBit 实现，充分的单元测试。
  bulk 长度按字节精确计算（UTF-8）、半帧检测（`Incomplete`）、嵌套数组、
  管线化流的首条回复消费。
- [x] **T7.2** 基于 `moonbitlang/async` TCP 的 Redis 客户端——`GET` / `SET` /
  `DEL` / `EXPIRE` / `PING`；服务端错误回复以 MoonBit error 形式抛出。
  对真实 redis-server 的集成测试覆盖全部命令，包括 WRONGTYPE 回复抛出
  `Failure`。
- [x] **T7.3** 缓存中间件——响应缓存，TTL 与缓存键可配置。架构说明：线性
  中间件模型（T4.3）没有 handler 后阶段，且 dispatch 是同步而 Redis 是
  async，所以缓存通过 `app.cache(client, ttl~, prefix~)` 挂载并放在 async
  服务层——http 定义 `CacheStore` trait 和泛型 `CachePolicy[S]`，cache 为
  `RedisClient` 实现该接口（无依赖环），`serve_cached_async` 在 dispatch
  前应答 GET 命中（`X-Cache: HIT`）并在返回途中存储 200 响应
  （`X-Cache: MISS`）。已对真实 Redis 走 HTTP 端到端验证。
- [x] **T7.4** 优雅降级——Redis 不可达时请求照常处理并在 stderr 记录警告
  （`cache unavailable, serving without cache`）；缓存写入失败绝不导致请求
  失败，并抑制 X-Cache 头。行为已在服务函数文档与 README 功能列表中说明，
  并有断连场景的端到端测试覆盖。

## T8 — WebSocket（ws/） `M3 · P1`

基于 `moonbitlang/async` 的 websocket 包——握手与 RFC 6455 帧由运行时提供。

- [x] **T8.1** 把运行时的 websocket 包接入 moonway 的 HTTP 服务。
  `WsRoute`（精确路径匹配）传给 `serve`/`serve_cached_async`；匹配的 GET
  请求经运行时的 `Conn::from_http_server` 升级（passthrough 模式），不再
  进入 dispatch。已用运行时 websocket 客户端的实时回显升级测试验证。
- [x] **T8.2** `app.ws(path, handler)`——把 websocket 连接桥接进 moonway
  路由；连接事件（`on_message`、`on_close`）与广播辅助函数。`WsConn` 以
  文本形式封装收发，框架运行接收循环并保证 `on_close` 恰好触发一次，
  `WsHub` 提供 join/leave/broadcast（单线程事件循环内无需加锁）。已用
  双客户端交叉广播 e2e 测试验证。
- [x] **T8.3** `examples/` 下的聊天示例——`examples/chat` 提供极简 HTML
  页面（原生 WebSocket API，无需构建步骤）和经 `WsHub` 广播的 `/chat`
  路由。已验证页面 HTTP 服务；WebSocket 路径与 T8.2 e2e 测试覆盖的
  hub 逻辑相同。

## T9 — Admin 管理后台（admin/） `M4 · P1`

- [x] **T9.1** 模型注册表——`app.admin(path, [Model])` 挂载。
  `app.admin(db, tables, prefix~, token~)` 为每张表注册 index/list/new/
  edit/update/delete 路由；请求现在携带 query string（`Request::query_param`，
  之前被剥掉丢弃），admin 通过新增的裸行 API
  （`select_raw`/`find_raw`/`insert_raw`/`update_raw`/`delete_raw`）操作
  任意表——无需具体模型类型。
- [x] **T9.2** 服务端渲染的 CRUD 界面——支持分页与搜索的列表、创建/编辑
  表单、带确认的删除。控件跟随 schema 列类型（文本用 textarea、布尔用
  checkbox、其余用 number 输入）；文本搜索是对文本列的 LIKE 且做引号
  转义；动作均为 303 重定向。渲染层是纯函数并有单元测试；完整 CRUD
  流程经 `app.handle` 做了集成测试。
- [x] **T9.3** 最小防护 *（可选）*——`app.admin(..., token=...)`：设置后，
  每个 admin 请求必须经 `?token=`（GET）或表单字段（POST）携带令牌，
  否则 401。已在 `App::admin` 文档注明这是基础防护、不是生产级认证。
  集成测试覆盖（拒绝、错误令牌、查询放行、POST 放行）。
- [ ] **T9.4** 截取 admin 后台截图，供 T12.4 使用。

## T10 — REPL 控制台（cli/） `M4 · P2`

- [ ] **T10.1** `moonway console`——加载应用配置与数据库连接。
- [ ] **T10.2** 查询解释器子集——解析 `<Model>.all()`、`<Model>.find(id)`、
  `<Model>.count()`、`insert`；这是方法调用式 DSL，**不是**通用语言求值器
  （有意为之的范围收缩）。
- [ ] **T10.3** 点命令——`.help`、`.tables`、`.quit`；提示符显示连接信息
  （`moonway 0.1.0 · connected to sqlite://app.db`）。

## T11 — Preact 前端集成（preact/） `M4 · P2`

- [ ] **T11.1** 生成项目中的前端脚手架——Preact + esbuild，`npm run build`
  产物输出到静态目录；文档写明需要 Node.js 环境。
- [ ] **T11.2** 静态文件服务——Content-Type、`index.html` 回退。
- [ ] **T11.3** 接入 posts API 的示例页面。

> P2：按风险预案可收缩——若收缩，删除 README 中对应功能条目并如实说明。

## T12 — 发布、示例与验收 `M3（T12.1）· M5`

- [ ] **T12.1** 尽早（M3）发布 `daqing/moonway@0.1.0` 到 mooncakes.io——在
  干净项目中验证 `moon add daqing/moonway` 与 `moon install daqing/moonway`。
- [ ] **T12.2** `examples/blog`——参考应用，覆盖模型、路由、缓存、WebSocket
  聊天与 admin。
- [ ] **T12.3** README 验收演练——在干净目录中逐字执行两份 README 的每一条
  命令；修代码或改文档，直到 100% 通过。
- [ ] **T12.4** README 截图——admin 后台（以及可选的演示 GIF）；移除
  `<!-- TODO -->` 占位注释。
- [ ] **T12.5** 最终发布——按需升版本号、打 annotated tag、写 changelog；
  勾选两份 README 中的路线图复选框。
