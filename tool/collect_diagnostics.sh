#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 一次收集所有診斷資訊，輸出成單一檔案。
# 卡住時把 diagnostics.txt 的內容整份貼出來即可，不用逐個指令試。
# ─────────────────────────────────────────────────────────────
set -uo pipefail
cd "$(dirname "$0")/.."
OUT=diagnostics.txt
: > "$OUT"

section () { echo "" >> "$OUT"; echo "===== $1 =====" >> "$OUT"; }
run     () { section "$1"; shift; "$@" >> "$OUT" 2>&1 || echo "(exit $?)" >> "$OUT"; }

{
  echo "JoinCrew 診斷報告"
  echo "時間：$(date)"
  echo "系統：$(uname -mrs)"
} >> "$OUT"

run "flutter --version"        flutter --version
run "flutter doctor -v"        flutter doctor -v
run "dart --version"           dart --version
run "flutter devices"          flutter devices

section "專案結構"
{
  for d in lib test tool supabase docs android ios web .vscode .claude; do
    [[ -e $d ]] && echo "✓ $d" || echo "✗ $d（不存在）"
  done
  echo "Dart 檔數：$(find lib test -name '*.dart' 2>/dev/null | wc -l | tr -d ' ')"
} >> "$OUT"

run "pubspec.yaml"             cat pubspec.yaml
run "flutter pub get"          flutter pub get
run "flutter pub deps --style=compact" flutter pub deps --style=compact

section "flutter analyze（完整輸出）"
flutter analyze >> "$OUT" 2>&1 || echo "(exit $?)" >> "$OUT"

section "analyze 統計"
{
  echo "error   : $(grep -c '^ *error'   "$OUT" 2>/dev/null || echo 0)"
  echo "warning : $(grep -c '^ *warning' "$OUT" 2>/dev/null || echo 0)"
  echo "info    : $(grep -c '^ *info'    "$OUT" 2>/dev/null || echo 0)"
} >> "$OUT"

section "error 等級明細（這些才是真的編譯不過）"
grep '^ *error' "$OUT" | sort | uniq -c | sort -rn | head -40 >> "$OUT" 2>/dev/null \
  || echo "（沒有 error）" >> "$OUT"

run "flutter test"             flutter test --reporter=compact

section "專案自訂檢查"
{
  python3 tool/typecheck.py  2>&1 | tail -12
  python3 tool/selfcheck.py  2>&1 | tail -12
} >> "$OUT"

echo
echo "已產出 $OUT（$(wc -l < "$OUT" | tr -d ' ') 行）"
echo
echo "重點摘要："
grep -E '^(error|warning|info) +:' "$OUT" || true
echo
echo "把整份 $OUT 貼出來即可診斷。"
