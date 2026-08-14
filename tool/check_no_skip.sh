#!/usr/bin/env bash
# 反造假：agent 最愛用 skip 讓測試「通過」。
set -uo pipefail
cd "$(dirname "$0")/.."
# 用 POSIX 字元類別而非 \s：BSD grep（macOS 預設）不支援 \s，
# 會導致樣式永遠不匹配 —— 檢查看似通過，其實從未執行。
HITS=$(grep -rEn "skip:[[:space:]]*true|@Skip\(|@Tags\(\['flaky'\]\)" test/ integration_test/ 2>/dev/null || true)
if [[ -n "$HITS" ]]; then
  echo "violation: 測試被跳過"; echo "$HITS"; exit 1
fi
echo "no skipped tests"
