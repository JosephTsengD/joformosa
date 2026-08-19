# 揪Formosa — 專案憲法

給 AI 協作者的必讀規則。違反這些規則的變更一律不予合併。

## 技術棧
Flutter 3.27+ / Dart 3.6+ · Riverpod 2（**不使用 code-gen**）· go_router ·
shared_preferences · Supabase（可選後端）

## 分層鐵律（由 tool/check_layering.sh 強制）
1. `domain/` 是純 Dart，**不得** `import 'package:flutter/...'`
2. `presentation/` **不得** import `data/`
3. feature 層**不得**出現 `Color(0x...)`，一律 `context.colors`
4. 全專案**禁止** `DateTime.now()`，一律 `ref.read(clockProvider).now()`
5. widget 中**不得**出現硬編碼的使用者可見中文字串，一律走 `Strings`

## 第三方 SDK 一律用前綴 import
```dart
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
```
理由：`supabase_flutter` 會轉出 gotrue 的 `Session`、`User`，與本專案
domain 的同名型別直接衝突。而編譯器的錯誤訊息會指向**我們**的 import 行，
看起來像是我們的檔案有問題，很難第一眼看懂。

前綴讓衝突不可能發生，也讓讀者一眼看出哪些型別來自外部。
由 `tool/typecheck.py` 的 T10 強制。

## 錯誤處理
`data/` 層負責把所有原始例外轉譯成 `AppFailure`。
`domain/` 與 `presentation/` 永遠不 catch 原始例外。

## 狀態
UI 狀態用 sealed class 顯式建模所有分支，用 switch 讓編譯器檢查窮盡性。
不要用 `AsyncValue` 的三態硬套五種情境。

## 測試
- 每個驗收條件（spec 的 `Scenario:`）都必須有標記 `// @spec {id}/Scenario-{name}` 的測試
- **不得**用 `skip` 讓測試通過
- 改測試而不改實作 = BLOCKER

## 分支
`main` 永遠可部署。功能從 `dev` 切 `feat/T-xxx-描述`，PR 回 `dev`。
見 `docs/BRANCHING.md`。

## 規格生命週期
`planned` → `spec_frozen` → `done`。
`tool/spec_coverage.py` 只對 `spec_frozen` 生效，讓規劃師能提前寫規格。
**凍結後不得為了配合實作而修改規格**——實作不了就回報 `spec_defect`。

## 檢查腳本一律用 Python，不用 shell
含 CJK 文字的 shell 腳本已經三次出錯：BSD sed/grep 不支援 `\s`（靜默失效）、
bash 3.2 把全形字元吃進變數名。這些錯誤的共通點是**訊息看不出真因**。

## 禁止頂層可變單例
`final router = GoRouter(...)`、`final controller = StreamController()` 這類
頂層宣告是全域可變狀態，整個 process 共用。一律改用 Provider。
由 `tool/selfcheck.py` 的 C10 強制。

## 完成的定義
`bash tool/harness.sh` 回傳 0。這是唯一標準，人與 AI 相同。

## 不要做的事
- 不要爬取 joindui.tw 或任何第三方網站的資料
- 不要為了讓檢查通過而放寬檢查本身
- 不要新增 spec 未列出的套件依賴
