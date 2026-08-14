# 版本相容性備忘

程式碼是以 Flutter 3.27 的 API 為基準撰寫的。你安裝的是最新 stable（3.44.x）。
兩者之間有九個版本的差距，以下是**預期可能出現、且已預先處理或有明確解法**的項目。

## 已預先處理

| 項目 | 說明 |
|---|---|
| `useMaterial3` | 已從 `ThemeData` 移除。M3 自 3.16 起是預設，新版把這個參數標為 deprecated |
| `withOpacity` → `withValues` | 全專案已使用 `withValues`，不受影響 |
| `WillPopScope` → `PopScope` | 已使用 `PopScope.onPopInvokedWithResult` |
| `textScaleFactor` → `TextScaler` | 已使用 `MediaQuery.textScalerOf` |
| `ColorScheme.background` 移除 | 已使用 `surface`，未使用 `background` |
| `go_router` / `flutter_lints` 版本 | 已放寬為區間，避免解析衝突 |

## 若出現，這樣處理

| 訊息 | 等級 | 處理 |
|---|---|---|
| `'useMaterial3' is deprecated` | info | 已處理；若仍出現代表你的 zip 是舊版 |
| `MaterialStateProperty is deprecated` | info | 改成 `WidgetStateProperty`（本專案未使用） |
| `Unrecognized lint rule: xxx` | warning | 該 lint 在新版 flutter_lints 已改名，從 `analysis_options.yaml` 移除那一行 |
| `The argument type 'X' can't be assigned` in Riverpod | **error** | Riverpod 被升到 3.x。`pubspec.yaml` 已鎖 `<3.0.0`，執行 `flutter pub get` 而非 `pub upgrade` |
| `flutter_lints >=8.0.0 requires SDK` | error | 把 `flutter_lints` 改成 `any` |

## 工具鏈之間的衝突

### `require_trailing_commas` vs 新版格式化器

Dart 3.7 引入 tall-style 格式化器，它會**自動決定**換行，並在構造能放進一行時
**移除**尾隨逗號。而 `require_trailing_commas` 這條 lint 要求加上。

結果是死循環：

```
dart fix --apply   → 加上尾隨逗號
dart format .      → 又把它移除
flutter analyze    → 再次抱怨缺少尾隨逗號
```

追蹤中的 issue：`dart-lang/dart_style#1652`、`dart-lang/sdk#61338`。

**本專案的決定：不啟用這條 lint。** 尾隨逗號原本的用途是手動強制換行，
而新格式化器已經自己做這個決定，規則因此失去意義。

若你在別的專案想保留手動控制，另一條路是：

```yaml
formatter:
  trailing_commas: preserve
linter:
  rules:
    - require_trailing_commas
```

兩者必須成對出現，只開一邊必定打架。

## Supabase 金鑰改名

`anonKey` 已被標記淘汰，新名稱是 `publishableKey`（值為 `sb_publishable_...`）。
Supabase 表示**舊的 anon key 會在 2026 年底停用**，所以這是該做的遷移，
不是可以忽略的 info。

本專案的處理：`AppConfig` 同時接受 `SUPABASE_PUBLISHABLE_KEY` 與
`SUPABASE_ANON_KEY` 兩個環境變數，優先用新的。這樣既有的 GitHub Secrets
不必立刻改名，遷移可以分兩步走。

若 `flutter analyze` 說 `publishableKey` 不存在，代表解析到較舊的
supabase_flutter：

```bash
flutter pub upgrade supabase_flutter
```

## 判斷準則

跑 `flutter analyze` 之後，**只看 `error` 等級**：

- `info` / `warning` → 風格問題，`dart fix --apply` 通常解決，不影響執行
- **`error`** → 真的編譯不過，必須修

`flutter run` 能跑起來，就代表沒有 error。harness 的 `analyze` 用 `--fatal-infos`
是刻意嚴格，那是 CI 的標準，不是「能不能跑」的標準。
