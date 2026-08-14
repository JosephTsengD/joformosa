#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 第一次拿到專案時跑這支。
# 它按「失敗成本由低到高」排序，每一關都印出**這一關失敗時該做什麼**，
# 而不是丟一堆紅字讓你自己猜。
# ─────────────────────────────────────────────────────────────
set -uo pipefail
cd "$(dirname "$0")/.."
STEP=0
fail() { echo; echo "✗ $1"; echo "  → $2"; exit 1; }
ok()   { echo "✓ $1"; }
step() { STEP=$((STEP+1)); echo; echo "[$STEP/8] $1"; }

step "檢查 Flutter 是否安裝"
command -v flutter >/dev/null || fail "找不到 flutter" \
  "安裝：brew install --cask flutter，或見 https://docs.flutter.dev/get-started/install/macos"
FV=$(flutter --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
ok "Flutter $FV"

step "檢查版本是否 >= 3.27（專案用到 Color.withValues / PopScope 新 API）"
MAJOR=${FV%%.*}; REST=${FV#*.}; MINOR=${REST%%.*}
if [[ $MAJOR -lt 3 || ( $MAJOR -eq 3 && $MINOR -lt 27 ) ]]; then
  fail "Flutter $FV 太舊" "執行 flutter upgrade；或用 FVM：fvm install 3.27.0 && fvm use 3.27.0"
fi
ok "版本符合"

step "檢查平台資料夾是否存在"
# 逐一檢查而非「全都不存在才建」：只建了 android/ios 而漏掉 web 時，
# 前面都會通過，直到最後 build_web 才失敗——那時已經浪費好幾分鐘。
MISSING=""
for plat in android ios web; do
  [[ -d $plat ]] || MISSING="${MISSING}${MISSING:+,}$plat"
done
if [[ -n "$MISSING" ]]; then
  echo "  缺少平台：$MISSING，正在產生…"
  flutter create . --org tw.joincrew --project-name joincrew \
    --platforms="$MISSING" >/dev/null \
    || fail "flutter create 失敗" "手動執行 flutter create . --platforms=$MISSING 看完整錯誤"
  echo "  ⚠ flutter create 可能覆寫 pubspec.yaml，請執行 git diff pubspec.yaml 檢查"
fi
# flutter create 會產生引用 MyApp 的樣板測試，本專案沒有該類別
if [[ -f test/widget_test.dart ]] && grep -q "MyApp" test/widget_test.dart 2>/dev/null; then
  rm -f test/widget_test.dart
  echo "  已移除 flutter create 產生的樣板測試 test/widget_test.dart"
fi
ok "平台資料夾就緒"

step "解析依賴"
flutter pub get >/dev/null || fail "pub get 失敗" \
  "多半是網路或版本衝突。試 flutter pub upgrade --major-versions"
ok "依賴解析完成"

step "套用官方格式（容器中無法執行，第一次一定有差異）"
dart format . >/dev/null && ok "格式已套用"

step "靜態分析"
if ! flutter analyze --fatal-infos > /tmp/analyze.log 2>&1; then
  echo "  分析有發現，前 20 筆："
  tail -25 /tmp/analyze.log | sed 's/^/    /'
  echo
  echo "  → 先試 dart fix --apply（可自動修掉絕大多數 lint），再跑一次本腳本。"
  echo "  → 若剩下的是 error 等級（不是 info/warning），那是真正的編譯錯誤，需要人工處理。"
  exit 1
fi
ok "靜態分析通過"

step "執行測試"
flutter test 2>&1 | tail -30 || fail "測試失敗" \
  "先看 test/smoke_test.dart —— 它失敗代表 App 根本開不起來，優先修它"
ok "測試通過"

step "建置 Web（最快的端到端證明）"
flutter build web --release >/dev/null 2>&1 \
  || fail "web 建置失敗" "執行 flutter build web 看完整輸出"
ok "Web 建置成功"

echo
echo "════════════════════════════════════════════"
echo " 專案可執行。啟動 demo："
echo "   flutter run -d chrome      # 最快"
echo "   flutter run                # 實機 / 模擬器"
echo "════════════════════════════════════════════"
