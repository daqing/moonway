# Git 钩子

## Pre-commit 钩子

这个 pre-commit 钩子会在每次提交前自动执行以下检查：

1. `moon fmt` —— 格式化所有 MoonBit 源码；如果格式化产生了改动，本次提交
   会被拒绝（把格式化后的文件加入暂存区后重新提交）。
2. `moon check` —— 静态诊断。
3. `moon test` —— 运行完整测试套件。

钩子还会把 `$HOME/.moon/bin` 加入 `PATH`，保证在默认路径不含 MoonBit
工具链的非交互 shell 中也能正常运行。

### 使用方法

1. 确保钩子具有可执行权限（如没有则执行）：
   ```bash
   chmod +x .githooks/pre-commit
   ```

2. 配置 Git 使用 `.githooks` 目录中的钩子：
   ```bash
   git config core.hooksPath .githooks
   ```

3. 之后执行 `git commit` 时钩子会自动运行。
