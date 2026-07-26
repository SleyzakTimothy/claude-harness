#!/usr/bin/env bash
# Stop hook：项目验证未通过时阻止结束回合（退出码 2 = 阻止，stderr 反馈给 Claude）。
# 仅当项目根目录存在 .harness/verify.sh 时生效；否则直接放行。
# 无限循环由 Claude Code 自带的连续阻止上限兜底。
set -u

cat > /dev/null  # 消费 stdin 的 hook 输入

# 定位项目根：会话 cwd 可能处于子目录，必须用 CLAUDE_PROJECT_DIR，否则验证会被静默绕过
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

[ -f ".harness/verify.sh" ] || exit 0

# 统一用 bash 执行：文件存在但无执行权限时同样不能放行
if command -v timeout >/dev/null 2>&1; then
  out=$(timeout 540 bash .harness/verify.sh 2>&1)
else
  out=$(bash .harness/verify.sh 2>&1)
fi
status=$?

if [ "$status" -eq 124 ]; then
  echo "闭环验证超时（>540 秒）被中止。请缩短 .harness/verify.sh 的耗时（拆分慢检查、只跑受影响的测试）后再结束回合。" >&2
  exit 2
fi

if [ "$status" -ne 0 ]; then
  {
    echo "闭环验证未通过：.harness/verify.sh 退出码 $status。修复问题并重跑验证后再结束回合；若验证脚本断言确已过时，修正脚本并在汇报中单独声明。"
    echo "--- 验证输出（末尾 40 行）---"
    printf '%s\n' "$out" | tail -40
  } >&2
  exit 2
fi

exit 0
