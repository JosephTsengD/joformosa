#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 唯一的真理來源。人與 AI 都跑同一個。
# exit code 就是「完成」的定義——agent 無法自己宣稱通過。
#
#   ./tool/harness.sh            全部檢查
#   ./tool/harness.sh --fast     只跑靜態檢查與單元測試
# ─────────────────────────────────────────────────────────────
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p .harness && : > .harness/raw.jsonl

FAST=0; [[ "${1:-}" == "--fast" ]] && FAST=1
FAIL_COUNT=0

run () {  # run <name> <blocker|warn> <cmd...>
  local name=$1 sev=$2; shift 2
  printf '  %-14s ' "$name"
  if out=$("$@" 2>&1); then
    st=pass; echo "✓"
  else
    st=fail
    [[ $sev == blocker ]] && { echo "✗ BLOCKER"; FAIL_COUNT=$((FAIL_COUNT+1)); } || echo "! warn"
    echo "$out" | tail -20 | sed 's/^/      /'
  fi
  printf '{"check":"%s","status":"%s","severity":"%s"}\n' "$name" "$st" "$sev" \
    >> .harness/raw.jsonl
}

echo "▸ 靜態檢查"
run format    blocker dart format --set-exit-if-changed --output=none .
run analyze   blocker flutter analyze --fatal-infos
run layering  blocker tool/check_layering.sh
run no_skip   blocker tool/check_no_skip.sh
run selfcheck blocker python3 tool/selfcheck.py
run typecheck blocker python3 tool/typecheck.py
run checker_mt blocker python3 tool/test_typecheck.py

echo "▸ 測試"
run unit      blocker flutter test --coverage
run spec_cov  blocker python3 tool/spec_coverage.py

if [[ $FAST -eq 0 ]]; then
  echo "▸ 建置"
  if [[ -d web ]]; then
    run build_web warn flutter build web --release
  else
    echo "  build_web       - 略過（尚未建立 web 平台）"
    echo "                    執行 flutter create . --platforms=web 後即可啟用"
  fi
fi

echo
if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "PASSED — 所有 blocker 檢查通過"; exit 0
else
  echo "FAILED — $FAIL_COUNT 個 blocker 未通過"; exit 1
fi
