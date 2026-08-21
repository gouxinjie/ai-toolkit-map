#!/usr/bin/env bash
# 一键提交并推送 GitHub + Gitee
set -e

cd "$(dirname "$0")"

# 提交信息：支持传参，缺省用当前时间
if [ -n "$1" ]; then
  MSG="$*"
else
  MSG="auto commit $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo "========================================"
echo " [1/3] git add ."
echo "========================================"
git add .

echo ""
echo "========================================"
echo " [2/3] git commit -m \"$MSG\""
echo "========================================"
git commit -m "$MSG" || echo "[提示] 没有可提交的更改，可直接 push"

echo ""
echo "========================================"
echo " [3/3] 一键 push 到 GitHub + Gitee"
echo "========================================"
git push origin

echo ""
echo "========================================"
echo "  ✔ 已同步到 GitHub 与 Gitee 两个仓库"
echo "========================================"
