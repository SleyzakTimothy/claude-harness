---
name: harness-init
description: 在当前项目初始化闭环 harness：创建 .harness/verify.sh 验证脚本、PROGRESS.md 进度文件，初始化 git，并在 CLAUDE.md 中写入会话协议。在一个新项目上首次使用 autonomy-harness 时运行。
---

# harness 初始化

在当前项目根目录完成以下设置（已存在的部分跳过，不要覆盖用户已有内容）：

## 1. git

若不是 git 仓库：`git init` 并做首次提交。确保 `.gitignore` 覆盖常见产物（依赖目录、缓存、密钥文件）。

## 2. .harness/verify.sh

创建 `.harness/verify.sh` 并 `chmod +x`。先探测项目类型，写入真实可用的验证命令：
- 有 `pytest.ini`/`tests/` 且为 Python → `python3 -m pytest tests/ -x -q`
- 有 `package.json` → `npm test`（确认 test script 存在）
- 有 `Dockerfile`/`compose.yml` → 追加 `docker compose build` 或构建检查
- 有 linter 配置 → 追加 lint 命令

模板：

```bash
#!/usr/bin/env bash
# 闭环验证：退出码 0 = 通过。每项检查失败立即退出并给出可定位的输出。
set -e
# <探测到的测试命令>
# <探测到的构建命令>
# <探测到的 lint 命令>
```

写完后**实际运行一次**确认脚本本身可用；若当前就不通过，如实告知用户现状，不要注释掉检查来"变绿"。

## 3. PROGRESS.md

创建进度文件，结构：

```markdown
# 项目进度
## 当前任务
（任务规格、验收标准）
## 已完成
## 进行中
## 未开始 / 已知问题
```

## 4. CLAUDE.md 会话协议

在项目 CLAUDE.md 中追加（无则创建）：

```markdown
## 闭环工作协议
- 每个任务按 autonomy-harness:closed-loop 技能执行。
- 会话开始：先读 PROGRESS.md 和 git log 恢复状态。
- 完成判定以 .harness/verify.sh 为准，验证不过不得宣告完成。
- 每个可验证子目标完成即 git commit，并同步更新 PROGRESS.md。
```

## 5. 收尾

git commit 以上全部内容，向用户报告：验证脚本包含哪些检查、当前是否通过。

## 下一步建议（汇报末尾必附）

- 用户已有具体任务 → 直接给出 `/autonomy-harness:closed-loop <该任务>` 供复制执行。
- 没有具体任务 → 告知以后用 `/autonomy-harness:go <一句话需求>` 作为万能入口即可，无需记住其他命令。
