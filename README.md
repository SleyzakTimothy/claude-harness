# migoachi-plugins

个人 Claude Code 插件市场。当前包含：

## autonomy-harness — 闭环自主工作流

把"人只提需求、AI 端到端完成"落地为可复用的 harness。基于 2026-07 深度调研结论：自主性的核心杠杆是可执行的外部验证，而非模型自我反思。

**组件**

| 组件 | 作用 |
|---|---|
| `closed-loop` 技能 | 五步闭环协议：规格锁定 → 定义可执行验证 → 执行-验证循环 → 独立终审 → 提交/更新进度 |
| `harness-init` 技能 | 一条命令为任意项目初始化 harness（verify.sh、PROGRESS.md、git、CLAUDE.md 协议） |
| `verifier` 子代理 | 新鲜上下文独立验收，不信任执行者的自我报告 |
| Stop hook | `.harness/verify.sh` 不通过时强制阻止收工 |

## 安装

```
# 本机路径安装（本地开发/测试）
/plugin marketplace add /opt/vultr/claude-harness
/plugin install autonomy-harness@migoachi-plugins

# 推到 GitHub 后，任何机器：
/plugin marketplace add <owner>/<repo>
/plugin install autonomy-harness@migoachi-plugins
```

## 使用

```
cd 你的项目
/autonomy-harness:harness-init        # 首次：初始化 verify.sh、PROGRESS.md、git
/autonomy-harness:closed-loop <任务>  # 之后：闭环执行任何任务
```

安装后 Stop hook 自动生效：只要项目里有 `.harness/verify.sh`，验证不通过 Claude 就无法宣告完成。

## 团队/多机自动预装

在目标项目 `.claude/settings.json` 写入：

```json
{
  "extraKnownMarketplaces": {
    "migoachi-plugins": { "source": { "source": "github", "repo": "<owner>/<repo>" } }
  },
  "enabledPlugins": { "autonomy-harness@migoachi-plugins": true }
}
```

成员打开项目即自动获得整套 harness。

## 安全与已知限制

- Stop hook 会自动执行项目根目录的 `.harness/verify.sh`。**打开来历不明的仓库前注意**：该文件属于项目方可控代码（与 npm scripts 同级风险），信任边界依赖 Claude Code 的工作区信任机制。
- 验证脚本执行有 540 秒超时（hook 总超时 600 秒），慢测试套件应拆分或只跑受影响子集。
- hook 为 bash 脚本，Windows 原生环境需 WSL/Git Bash。

