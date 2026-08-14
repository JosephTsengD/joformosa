# JoinCrew 建置與運行手冊

寫給第一次接手這個專案的人。假設你有一台 Mac、裝過 Homebrew，其他都不假設。

照著做，大約 40 分鐘（其中 30 分鐘在等下載）。

---

## 目錄

- [Part 0：先讀這段](#part-0先讀這段)
- [Part 1–2：安裝 Flutter 環境](#part-12安裝-flutter-環境) → 見 `INSTALL.md`
- [Part 3：讓專案跑起來](#part-3讓專案跑起來)
- [Part 4：跑測試與品質閘門](#part-4跑測試與品質閘門)
- [Part 5：Demo 操作腳本](#part-5demo-操作腳本)
- [Part 6：接上真實後端](#part-6接上真實後端選讀)
- [Part 7：疑難排解](#part-7疑難排解)
- Part 8：部署上線 → 見 [`docs/DEPLOY.md`](docs/DEPLOY.md)
- [附錄：指令速查](#附錄指令速查)

---

## Part 0：先讀這段

### 這個專案現在的狀態

程式碼是在**沒有 Flutter SDK 的環境**中產生的。所有能靜態驗證的都驗證過了
（見 `docs/TEST_AUDIT.md`），但**沒有經過編譯器**。

這代表什麼？

- 結構性錯誤（打錯字、參數不存在、import 找不到）已被 `tool/typecheck.py` 攔掉
- **格式與 lint 幾乎確定有待修**，一行 `dart fix --apply` 解決
- 極少數需要完整型別推導才能發現的錯誤，只有真正的 analyzer 抓得到

所以 Part 3 的流程是設計成「**讓編譯器當最後一道關卡**」，而不是假裝已經沒問題。
遇到紅字不要慌，Part 7 有對照表。

### 兩種執行模式

| 模式 | 需要什麼 | 適合 |
|---|---|---|
| **A. 合成資料**（預設） | 什麼都不用 | 開發、demo、面試 |
| **B. 真實 Supabase** | Docker + Supabase CLI | 想展示後端能力時 |

**先跑模式 A。** 它不需要網路、不需要金鑰、不需要後端，
25 個社團與約 150 場活動都是程式產生的。

---

## Part 1–2：安裝 Flutter 環境

**已移到獨立文件:[`INSTALL.md`](INSTALL.md)。**

先把那份做完,確認以下四行都成功,再回來看 Part 3:

```bash
flutter --version     # 3.27 以上,建議最新 stable(3.44.x)
flutter doctor        # Flutter 與 Chrome 為綠勾即可
dart --version        # Flutter 內建,不需另外安裝
flutter devices       # 至少列出 Chrome
```

版本要求的由來:專案用了 `Color.withValues()`（Flutter 3.27 起）與
`PopScope.onPopInvokedWithResult`（3.24 起）。用更舊的版本會看到一堆
`The method 'withValues' isn't defined`。

---

## Part 3：讓專案跑起來

### 3.1 解壓縮

```bash
unzip joincrew-flutter.zip
cd joincrew
```

### 3.2 產生平台資料夾（**這步不能跳過**）

壓縮檔裡只有原始碼，**沒有** `android/`、`ios/`、`web/`。

為什麼？那些資料夾有數百個檔案，內容跟你的 Flutter 版本、Gradle 版本、
Xcode 版本綁定。我先寫死一份給你，反而會因為版本不合而爆炸。
讓 `flutter create` 依你的環境現場產生，才是對的做法。

```bash
flutter create . --org tw.joincrew --project-name joincrew \
  --platforms=android,ios,web
```

在既有目錄執行時，它**只補缺少的檔案**，不會動你的 `lib/`。

但它可能改寫 `pubspec.yaml`。檢查一下：

```bash
git init 2>/dev/null; git add -A 2>/dev/null   # 還沒有 git 的話先建
git diff pubspec.yaml
```

如果它加了 `cupertino_icons` 之類的，留著沒關係。
如果它動到 `environment:` 的 sdk 版本，**改回 `>=3.6.0 <4.0.0`**。

### 3.2b 刪除樣板測試（**必做**）

`flutter create .` 會產生 `test/widget_test.dart`，它引用 Flutter 預設範例的
`MyApp` 類別。本專案沒有這個類別，留著會讓 `flutter test` 直接編譯失敗。

```bash
rm -f test/widget_test.dart
```

### 3.3 安裝依賴

```bash
flutter pub get
```

### 3.4 讓編譯器把關（**最重要的兩行**）

```bash
dart format .
dart fix --apply
```

- `dart format` 套用官方格式。第一次一定有大量變動，這是正常的。
  **這一步是寫入檔案；harness 的 `format` 檢查只是比對、不會幫你改。**
  所以 harness 的 format 失敗時，解法永遠是回來跑一次 `dart format .`。
  行寬由 `analysis_options.yaml` 的 `formatter: page_width: 90` 決定
  （非預設的 80，因為 CJK 註解在 80 欄太窄）。
- `dart fix --apply` 自動修 lint：補上缺的 trailing comma、
  把能加 `const` 的都加上、移除多餘的型別註記。
  這一行通常能解決 90% 的 `flutter analyze` 紅字。

然後：

```bash
flutter analyze
```

**看到什麼就做什麼：**

| 輸出 | 意思 | 怎麼辦 |
|---|---|---|
| `No issues found!` | 完美 | 往下走 |
| 一堆 `info` | 風格建議 | 可以先忽略，或再跑一次 `dart fix --apply` |
| 有 `warning` | 有疑慮但能編譯 | 可以先往下走，之後再處理 |
| 有 **`error`** | **編譯不過** | 必須修，見 Part 7 |

### 3.5 跑起來

```bash
# 最快：Chrome
flutter run -d chrome

# iOS 模擬器
open -a Simulator && flutter run

# 看有哪些裝置可用
flutter devices
```

第一次建置會慢（Web 約 1 分鐘，iOS 約 3–5 分鐘）。之後有快取就快了。

### 3.6 確認成功

畫面上應該看到：

- 標題 `JoinCrew`，副標寫「今天有 N 場團練」
- 一排運動 chip：全部 / 跑步 / 自行車 / HYROX / 其他
- 幾張社團卡片，左側有彩色條，右上角有橘色積分

**開發時的兩個快捷鍵**（在 `flutter run` 的終端機按）：

- `r` — hot reload，改完 UI 按一下，0.5 秒生效，狀態保留
- `R` — hot restart，改了 provider 或 main 時用，狀態會重置

---

## Part 4：跑測試與品質閘門

### 4.1 一鍵驗證

```bash
bash tool/verify_demo.sh
```

它會照「失敗成本由低到高」逐關檢查，每關失敗都直接告訴你該做什麼。

### 4.2 跑測試

```bash
flutter test
```

**如果只有一個測試該優先修，是 `test/smoke_test.dart`。**
它把整個 App 完整啟動一次，驗證五件事：

1. 能不能渲染出社團卡片
2. 後端失敗時是否顯示錯誤與重試（而不是白畫面）
3. 沒有結果時是否有空狀態文案
4. 點卡片能不能導覽到詳情頁
5. 深色模式下整棵 widget 樹會不會拋錯

它過了，demo 當場黑畫面的機率就很低。

單獨跑一個檔案：

```bash
flutter test test/smoke_test.dart
```

看覆蓋率：

```bash
flutter test --coverage
brew install lcov
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

### 4.3 完整品質閘門

```bash
bash tool/harness.sh
```

這支跑十項檢查，`exit 0` 就是「完成」的定義 —— 人和 AI 都用同一個標準。

| 檢查 | 在驗什麼 |
|---|---|
| `format` | 官方格式 |
| `analyze` | 靜態分析（`--fatal-infos`） |
| `layering` | 分層鐵律：domain 不得 import flutter、禁用 `DateTime.now()`、禁硬編碼色碼 |
| `no_skip` | 沒有測試被 `skip` 掉 |
| `selfcheck` | 8 類編譯阻斷問題 |
| `typecheck` | 7 類專案型別誤用 |
| `checker_mt` | **變異測試：驗證上面兩支檢查器本身有效** |
| `unit` | 全部測試 |
| `spec_cov` | 每條驗收條件都有對應測試 |
| `build_web` | 真的能建置 |

`checker_mt` 那項值得特別說：它會故意注入 6 個已知缺陷，確認檢查器每個都攔得住，
然後還原。**一個從不報錯的檢查器，和沒有檢查器是一樣的。**

---

## Part 5：Demo 操作腳本

面試或展示時照這個順序走，每一步都有可以講的技術點。

| # | 操作 | 講什麼 |
|---|---|---|
| 1 | 開啟 App | 「標頭是情境化的 —— 今天有場次就顯示數量，沒有才顯示 slogan」 |
| 2 | 快速連點三個運動 chip | 「有 300ms debounce 加請求序號，只會發一次請求，舊回應會被丟棄」 |
| 3 | 一路捲到底 | 「keyset 分頁，不是 offset。offset 在資料變動時會漏也會重」 |
| 4 | 指第三張沒有活動的卡 | 「種子資料刻意植入五類髒資料，這張測的是空活動不能變成空白區塊」 |
| 5 | 點進詳情、點積分卡 | 「原站的積分是黑箱，我補了明細與更新時間 —— 這是產品缺口不是技術缺口」 |
| 6 | 指活動時間軸 | 「狀態不存資料庫，由時間推導。存欄位就要靠排程翻轉，而排程一定會在時區邊界出錯」 |
| 7 | 切深色模式（我的頁面） | 「深色不是把亮色反轉，elevation 用提高亮度表達」 |
| 8 | 進團長後台、新增活動 | 「冪等鍵在進入表單時產生而非送出時，所以網路重試不會產生兩筆」 |
| 9 | 表單打一半按關閉 | 「未儲存警告。honeypot 欄位抽成純函式才測得到 —— 隱藏欄位在 widget test 裡沒辦法 enterText」 |
| 10 | 終端機跑 `bash tool/harness.sh` | 「這是完成的定義。包含變異測試，確保檢查器本身有效」 |

Web 版另外可以展示：把網址列的 `/crews/xxx` 直接貼給對方開 —— 深連結三平台一致。

---

## Part 6：接上真實後端（選讀）

模式 A 已經足夠 demo。這段是想額外展示後端能力時再做。

```bash
# 1. 裝工具
brew install supabase/tap/supabase
# 需要 Docker Desktop 正在執行

# 2. 啟動本地 Supabase
cd joincrew
supabase start          # 第一次會拉映像檔，約 5 分鐘
supabase db reset       # 套用 supabase/migrations/ 的四個 SQL

# 3. 記下輸出的 API URL 與 anon key
cp env/dev.example.json env/dev.json
# 編輯 env/dev.json，把 URL 與 key 填進去，並把 USE_FAKE_BACKEND 設為 false

# 4. 開啟 Supabase 實作
#    - pubspec.yaml：取消 supabase_flutter 的註解
#    - lib/features/crew_discovery/data/supabase_crew_repository.dart：
#      移除開頭的 /* 與結尾的 */
#    - lib/app/providers.dart：把 crewRepositoryProvider 指向 SupabaseCrewRepository
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

⚠ `supabase_crew_repository.dart` 整份是註解狀態，**從未被編譯過**。
啟用時預期要修幾個型別錯誤，這是正常的。

LINE 登入的設定見 `SETUP.md` 第 5 節與 `docs/adr/007-line-login.md`。
**channel secret 絕對不可以進 App 或 git。**

---

## Part 7：疑難排解

### 編譯錯誤

| 錯誤訊息 | 原因 | 解法 |
|---|---|---|
| `The method 'withValues' isn't defined` | Flutter < 3.27 | `flutter upgrade` 或 `fvm use 3.27.0` |
| `onPopInvokedWithResult isn't defined` | Flutter < 3.24 | 同上 |
| `Target of URI doesn't exist: 'package:xxx'` | 沒跑 pub get | `flutter pub get` |
| `No such file or directory: android/` | 沒跑 flutter create | 回到 3.2 |
| 一堆 `prefer_const_constructors` | 沒跑 dart fix | `dart fix --apply` |
| `Expected to find ','`（大量） | 沒跑 format | `dart format .` |

### 執行期錯誤

| 現象 | 原因 | 解法 |
|---|---|---|
| 白畫面、無錯誤 | provider 沒被 override | 檢查 `main.dart` 有 `sharedPrefsProvider.overrideWithValue(prefs)` |
| `Bad state: overridden in main()` | 同上 | 同上 |
| `GoError: no GoRouter found` | widget test 沒給 router | 見 `test/widget/register_crew_test.dart` 的寫法 |
| 卡在骨架屏不動 | repository 沒回傳 | 檢查 `FakeCrewRepository` 的 `latency` |
| 中文變成方框 | 字型 fallback | 模擬器問題，實機正常。或在 `AppText` 補 fontFamily |

### 測試錯誤

| 現象 | 原因 | 解法 |
|---|---|---|
| `pumpAndSettle timed out` | 有無限動畫沒停 | 改用 `await tester.pump(Duration(milliseconds: 100))` 迴圈 |
| `A RenderFlex overflowed` | 測試視窗太小 | 設 `tester.view.physicalSize` |
| `Null check operator used on a null value` | Fake 資料的髒資料案例 | 這是好事，代表測試抓到了。修程式碼不要修測試 |

### 工具錯誤

| 現象 | 解法 |
|---|---|
| `tool/harness.sh: Permission denied` | `chmod +x tool/*.sh` |
| `python3: command not found` | `brew install python3`（selfcheck / typecheck 需要） |
| harness 的 `format` 一直失敗 | 先跑 `dart format .` 再跑 harness |

### 還是卡住

按這個順序：

```bash
flutter clean
rm -rf .dart_tool build
flutter pub get
flutter run -d chrome -v      # -v 印出詳細日誌
```

`flutter doctor -v` 的輸出貼給人看，通常一眼就知道是什麼。

---

## 附錄：指令速查

```bash
# 環境
flutter --version                  # 看版本
flutter doctor -v                  # 檢查環境
flutter devices                    # 看可用裝置

# 開發
flutter pub get                    # 裝依賴
flutter run -d chrome              # 跑 Web
flutter run                        # 跑預設裝置
#   r = hot reload   R = hot restart   q = 離開

# 品質
dart format .                      # 格式化
dart fix --apply                   # 自動修 lint
flutter analyze                    # 靜態分析
flutter test                       # 跑測試
flutter test --coverage            # 含覆蓋率

# 專案自訂
bash tool/verify_demo.sh           # 首次驗證（照失敗成本排序）
bash tool/harness.sh               # 完整品質閘門
bash tool/harness.sh --fast        # 跳過建置
python3 tool/typecheck.py          # 型別檢查
bash tool/test_typecheck.sh        # 驗證檢查器本身有效

# 建置
flutter build web --release
flutter build apk --release
flutter build ios --release --no-codesign

# 卡住時
flutter clean && flutter pub get
```
