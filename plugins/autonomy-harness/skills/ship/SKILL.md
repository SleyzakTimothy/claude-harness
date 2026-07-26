---
name: ship
description: 部署闭环：预检 → 记录回滚点 → 构建 → 部署 → 健康检查 → 失败自动回滚 → 汇报。适用于把当前项目的最新代码发布到运行环境（docker compose 或项目自带部署方式）。
---

# 部署闭环

部署是高风险操作，严格按以下顺序执行，任何一步失败都不得跳过后续检查直接宣告成功。

## 1. 预检（不通过则中止，不开始部署）

- 工作区必须干净：`git status` 无未提交改动（有则先提交或明确告知用户后中止）。
- 验证必须先过：运行 `.harness/verify.sh`，红的代码不部署。
- 探测部署方式：有 `compose.yml`/`docker-compose.yml` → docker compose 路径；有项目自带部署脚本（`deploy.sh`、package.json 的 deploy script 等）→ 用项目自带的；两者都无 → 停下来向用户确认部署方式（这属于"方向性且猜错代价高"，允许打断）。

## 2. 记录回滚点

- `git tag ship-<日期>-<序号>` 标记本次部署的代码版本。
- docker 路径：记录当前正在运行的镜像 ID（`docker compose images` / `docker ps --format`），这是回滚目标。首次部署无运行实例则记"无回滚点，失败即停止服务"并继续。

## 3. 构建与部署

- docker 路径：`docker compose build` → `docker compose up -d`。
- 构建失败：直接中止，现状未动，报告失败原因。

## 4. 健康检查（部署成败以此为准，不以命令退出码为准）

- 容器/进程存活：`docker compose ps` 全部 Up，无重启循环。
- 接口探活：对服务端口做 curl（从 `.env`、compose 端口映射、README 推断端点），比对预期响应；连续失败重试 3 次、间隔 5 秒。
- 日志扫描：`docker compose logs --since 2m` 无 ERROR/Traceback/panic 级别输出。

## 5. 失败自动回滚

健康检查任何一项不过：
- 用第 2 步记录的镜像 ID 回滚（`docker compose up -d` 指回旧镜像，或 `git checkout <上一个 ship 标签>` 后重建），回滚后**重跑同一套健康检查**确认旧版本恢复。
- 回滚后如实报告：部署失败、已回滚、失败证据（日志/探活输出）、建议的修复方向。**绝不在失败后为了"部署成功"降低健康检查标准。**

## 6. 汇报

成功：部署了哪个版本（commit/tag）、健康检查各项结果、回滚点是什么。
失败：卡在哪一步、证据、当前服务状态（已回滚到旧版/已停止）、下一步建议。
最后更新 `PROGRESS.md` 部署记录。
