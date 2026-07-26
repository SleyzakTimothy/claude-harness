#!/usr/bin/env bash
# Stop hook：项目验证未通过时阻止结束回合（退出码 2 = 阻止，stderr 反馈给 Claude）。
# 仅当项目根目录存在可执行的 .harness/verify.sh 时生效；否则直接放行。
# 无限循环由 Claude Code 自带的连续阻止上限兜底。
set -u

cat > /dev/null  # 消费 stdin 的 hook 输入

[ -x ".harness/verify.sh" ] || exit 0

out=$(./.harness/verify.sh 2>&1)
status=$?

if [ "$status" -ne 0 ]; then
  {
    echo "闭环验证未通过：.harness/verify.sh 退出码 $status。修复问题并重跑验证后再结束回合；若验证脚本本身已过时，先修正脚本并向用户说明。"
    echo "--- 验证输出（末尾 40 行）---"
    printf '%s\n' "$out" | tail -40
  } >&2
  exit 2
fi

exit 0
