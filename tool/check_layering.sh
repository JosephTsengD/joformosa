#!/usr/bin/env bash
# 分層依賴規則。寫在 README 裡沒人遵守，寫成 CI 檢查才有力量。
set -uo pipefail
cd "$(dirname "$0")/.."
ERR=0

# 規則 1：domain 層必須是純 Dart，不得 import flutter
if grep -rln "package:flutter/" lib/features/*/domain/ 2>/dev/null | grep -q .; then
  echo "violation: domain 層出現 flutter import"
  grep -rln "package:flutter/" lib/features/*/domain/
  ERR=1
fi

# 規則 2：presentation 不得直接 import data 或 infrastructure
if grep -rn "import.*\/data\/" lib/features/*/presentation/ 2>/dev/null | grep -v "^Binary" | grep -q .; then
  echo "violation: presentation 直接 import data 層"
  grep -rn "import.*\/data\/" lib/features/*/presentation/
  ERR=1
fi

# 規則 3：feature 層不得出現硬編碼色碼（必須走 Design Token）
HITS=$(grep -rn "Color(0x" lib/features/ 2>/dev/null \
       | grep -v ":[0-9]*: *//" \
       | grep -v "_lineGreen" || true)
if [[ -n "$HITS" ]]; then
  echo "violation: feature 層硬編碼色碼（請改用 context.colors）"
  echo "$HITS"; ERR=1
fi

# 規則 4：禁止 DateTime.now()（必須注入 Clock，否則時間邊界無法測試）
HITS=$(grep -rn "DateTime\.now()" lib/ 2>/dev/null \
       | grep -v "core/utils/clock.dart" \
       | grep -v ":[0-9]*: *//" || true)
if [[ -n "$HITS" ]]; then
  echo "violation: 直接呼叫 DateTime.now()（請用 ref.read(clockProvider).now()）"
  echo "$HITS"; ERR=1
fi

[[ $ERR -eq 0 ]] && echo "layering ok"
exit $ERR
