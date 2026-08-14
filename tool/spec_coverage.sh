#!/usr/bin/env bash
# spec ↔ test 的機器可驗證連結。
#
# docs/tasks/*.spec.md 裡的每個 `Scenario: X` 都必須有一個測試檔用
#   // @spec T-042/Scenario-X
# 標記。少一個就 fail —— AI 想混也混不過去。
set -uo pipefail
cd "$(dirname "$0")/.."
MISSING=0

shopt -s nullglob
for spec in docs/tasks/*.spec.md; do
  id=$(basename "$spec" .spec.md)
  while IFS= read -r line; do
    # BSD sed 不支援 \s。用 [[:space:]] 才能跨 macOS / Linux。
    # 原本的寫法在 macOS 上會留下開頭空白，被 tr 轉成 "-Xxx"，
    # 於是每一條驗收條件都被誤判為「沒有測試」。
    name=$(echo "$line" | sed 's/.*Scenario:[[:space:]]*//' | tr -d '\r' | tr ' ' '-')
    [[ -z "$name" ]] && continue
    if ! grep -rq "@spec $id/Scenario-$name" test/ integration_test/ 2>/dev/null; then
      echo "missing test for $id / Scenario: $name"
      MISSING=$((MISSING+1))
    fi
  done < <(grep -h "Scenario:" "$spec" 2>/dev/null || true)
done

if [[ $MISSING -gt 0 ]]; then
  echo "$MISSING 個驗收條件沒有對應測試"; exit 1
fi
echo "spec coverage ok"
