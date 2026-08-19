# 專案自我審查報告

日期：2026-08-12　審查者：AI 測試工程師角色　工具：`tool/selfcheck.py`

## 誠實聲明（最重要的一段）

產出這份骨架的環境**沒有 Flutter SDK**。因此：

| 項目 | 是否已驗證 |
|---|---|
| 括號 / 引號結構 | ✅ 機械驗證 |
| 建構子具名參數正確性 | ✅ 機械驗證（`typecheck.py` T1/T2）|
| static / enum 成員存在 | ✅ 機械驗證（T3）|
| Strings 字典 key 存在 | ✅ 機械驗證（T4）|
| pattern 解構欄位存在 | ✅ 機械驗證（T5）|
| implements 實作完整 | ✅ 機械驗證（T6）|
| sealed switch 窮盡性 | ✅ 機械驗證（T7）|
| **檢查器本身有效** | ✅ 變異測試 6/6 攔截 |
| import 全部可解析 | ✅ 機械驗證 |
| 跨檔案型別引用完整 | ✅ 機械驗證 |
| 分層規則 · 反跳過 · spec 覆蓋 | ✅ 機械驗證 |
| **`dart format` 格式** | ❌ **未執行** |
| **`flutter analyze` 靜態分析** | ❌ **未執行** |
| **`flutter test` 測試實際通過** | ❌ **未執行** |
| **`flutter build` 編譯成功** | ❌ **未執行** |

任何人告訴你「這份程式碼保證可以跑」而他沒編譯過，那是猜測不是結論。
所以請先跑 `bash tool/verify_demo.sh`，它會照失敗成本由低到高逐關驗證。

## 審查中實際發現並修正的缺陷

這些不是假設，是腳本真的抓到的：

| 編號 | 嚴重度 | 問題 | 修正 |
|---|---|---|---|
| F-1 | BLOCKER | `fake_auth_repository` 直接呼叫 `DateTime.now()`，違反可測時間規則 | 新增 `core/utils/id_gen.dart`，改用隨機 ID |
| F-2 | BLOCKER | `check_layering.sh` 的 grep 有例外條款，等於規則留後門 | 移除例外，改為修程式碼而非放寬規則 |
| F-3 | MAJOR | layering 檢查誤判註解行 | grep 加 `-v ":[0-9]*: *//"` |
| F-4 | BLOCKER | T-060 的 `UnsavedGuard` / `Honeypot` 兩條驗收條件沒有對應測試 | 補 `register_crew_test.dart`、抽出 `SubmissionGuard` 純函式並補測試 |
| F-5 | BLOCKER | `register_crew_test` 以 `MaterialApp(home:)` 掛載會呼叫 `context.go()` 的畫面，執行時必拋 `GoError` | 改用 `MaterialApp.router` + 真實 `GoRouter` |
| F-6 | MAJOR | `CrewCard` 用 `ExcludeSemantics` 包住整張卡，連收藏鈕的語意一起蓋掉 | 改為卡片給整體語意、收藏鈕保留自己的 `Semantics` |
| F-7 | MAJOR | `discovery_screen` 用 `dynamic ctrl` 並 `as VoidCallback` 硬轉 | 改為具體型別 `CrewListController` |
| F-8 | MINOR | `pubspec` 宣告 `intl` 但從未 import | 移除 |
| F-9 | MINOR | `Motion` token 定義了卻沒人用（死 token） | 用於 `FilterChipButton` 的選中態過渡 |

### 第二輪：迷你型別檢查器（`tool/typecheck.py`）

嘗試在容器中安裝 Flutter 失敗——`storage.googleapis.com` 與 `pub.dev`
都被 proxy 拒絕（403），只有 GitHub 可達，而 dart-sdk 與所有套件都在那兩個網域。
編譯這條路在此環境是死的，因此改為自建針對專案自訂型別的檢查器。

過程中修正的是**檢查器自己的四個 parser 缺陷**，程式碼本身沒有新缺陷：

| 編號 | 問題 | 修正 |
|---|---|---|
| P-1 | `split_top` 把 `=>` 的 `>` 當閉合括號，參數列被切爛 → 157 個假警報 | 不再把 `< >` 當括號，並先把 `=>` 正規化 |
| P-2 | 建構子解析抓到呼叫端並覆蓋真正的宣告 | 前一個非空白字元必須是 `{ } ;` 才算宣告 |
| P-3 | 把建構子宣告本身當呼叫端檢查 | 參數列含 `this.` / `required` / `super.` 即為宣告 |
| P-4 | T7 從 body 中「被建構的型別」猜 switch 主體 | 改為只看 case pattern 的頭型別 |
| P-5 | 變異測試腳本在 `set -o pipefail` 下永遠判為失敗 | 先收集輸出到變數再 grep |

### 變異測試（`tool/test_typecheck.sh`）

一個從不報錯的檢查器和沒有檢查器是一樣的，所以檢查器本身也要被測。
故意注入 6 個已知缺陷，全數攔截：

| 注入的缺陷 | 攔截 |
|---|---|
| 建構子具名參數打錯字 `activityScore` → `activitySore` | ✅ T1 |
| 移除 required 參數 `locationName` | ✅ T2 |
| static 成員不存在 `Space.lg` → `Space.huge` | ✅ T3 |
| Strings key 打錯字 `filterClear` → `filterClaer` | ✅ T4 |
| pattern 解構欄位 `crews` → `crewz` | ✅ T5 |
| sealed switch 刪掉 `CrewListEmpty` 分支 | ✅ T7 |

## 已知殘餘風險（尚未驗證，依可能性排序）

1. **`flutter analyze --fatal-infos` 幾乎確定會有發現。**
   `analysis_options.yaml` 開了 `require_trailing_commas`、`prefer_const_constructors`、
   `always_declare_return_types` 等嚴格規則，而這些程式碼從未經過 analyzer。
   **絕大多數可用 `dart fix --apply` 一鍵修掉。**
   判斷準則：`info` / `warning` 等級是風格問題，`error` 等級才是真的編譯不過。

2. **`dart format` 一定會產生 diff。** 這不是錯誤，先跑 `dart format .`。

3. **`pumpAndSettle` 可能逾時的理論風險。**
   `SkeletonCard` 用 `repeat(reverse: true)` 無限動畫。骨架屏只在資料到達前存在，
   測試用 `latency: Duration.zero` 所以會立刻被替換掉——但如果哪天有人改了載入邏輯
   讓骨架屏常駐，所有用 `pumpAndSettle` 的測試都會逾時。
   若遇到，改用 `await tester.pump(Duration(milliseconds: 100))` 迴圈。

4. **Riverpod 2.x 的 `Ref` 型別簽章。**
   程式中一律寫 `(Ref ref)` 而非 `(ProviderRef<T> ref)`，這依賴 Dart 函式參數的
   逆變性。理論上合法，但 riverpod 版本若有變動需複驗。

5. **`SupabaseCrewRepository` 整份被 `/* */` 註解。**
   這是刻意的（見 README「兩種執行模式」），但代表它**從未被編譯過**。
   啟用時預期需要修數個型別錯誤。

## 測試清單現況

| 層級 | 檔案 | 覆蓋重點 |
|---|---|---|
| 冒煙 | `test/smoke_test.dart` | App 能否啟動、錯誤態、空態、導覽、深色模式 |
| 單元 | `session_status_test` | 狀態推導、跨午夜、無 endsAt 預設 |
| 單元 | `formatters_test` | 相對時間、日界線陷阱 |
| 單元 | `crew_filter_test` | 篩選 ↔ URL 雙向轉換 |
| 單元 | `fake_repository_test` | 分頁不重不漏、排序、冪等、失敗轉譯 |
| 單元 | `submission_guard_test` | honeypot 判斷 |
| Widget | `crew_card_test` | NEW 徽章、無活動、超長名、2.0 字級、收藏態 |
| Widget | `register_crew_test` | 未儲存警告、取消返回、同意條款門檻 |

## 第三輪：macOS 實機首次執行（2026-08-13）

**首次在真實 Flutter 3.44 環境執行。`build_web` 通過，smoke test 全數通過 ——
App 本身可編譯、可執行。** 5 個 blocker 全部來自測試與工具，非 App 程式碼。

| 編號 | 嚴重度 | 問題 | 根因 | 修正 |
|---|---|---|---|---|
| M-1 | **BLOCKER（隱蔽）** | `check_no_skip` 顯示通過，但實際從未執行 | BSD grep 不支援 `\s`，樣式永遠不匹配 | 改用 `[[:space:]]` 並加 `-E` |
| M-2 | BLOCKER | `spec_cov` 回報 9 條驗收條件全部缺測試 | BSD sed 不支援 `\s`，殘留空白被 `tr` 轉成 `-Xxx` | 改用 `[[:space:]]` |
| M-3 | BLOCKER | `checker_mt` 執行失敗 | BSD sed 的 `-i` 需要備份字尾參數，語法與 GNU 不同 | 整支改寫為 `tool/test_typecheck.py` |
| M-4 | BLOCKER | `crew_filter_test` 編譯失敗 | `const` 集合的元素型別 `StyleTag` 覆寫了 `==` | 移除該處 const，並新增 **T8** 靜態檢查 |
| M-5 | BLOCKER | `test/widget_test.dart` 編譯失敗 | `flutter create .` 產生的樣板檔引用不存在的 `MyApp` | 刪除；`test/README.md` 記載 |
| M-6 | MAJOR | `未勾選同意條款時送出按鈕為停用` 失敗 | 按鈕在 ListView 底部，**懶載入未 build** | 先 `scrollUntilVisible` |

### M-1 值得單獨說明

`check_no_skip` 在 macOS 上顯示 ✓，但那是**假的通過**。BSD grep 不支援 `\s`，
所以 `skip:[空白]*true` 從未匹配任何東西。

這比直接失敗更危險：一個永遠顯示綠燈的檢查，會讓人以為防線存在。
**跨平台的 shell 檢查腳本必須在兩個平台都跑過，否則不能算數。**
之後新增的檢查一律優先用 Python 而非 shell。

### M-7：唯一一個 App 程式碼的真實缺陷

```
lib/features/auth/data/fake_auth_repository.dart:50:30: Error: Not a constant expression.
    return const Ok<AppUser>(u);
```

`u` 是區域變數。即使它以 `const AppUser(...)` 初始化，**變數本身不是編譯期常數**，
不能作為 `const` 建構子的引數。

值得注意的是：這個錯誤在 `flutter build web` 通過的那一輪並未浮現，
只有在測試載入 `fake_auth_repository.dart` 時才被前端編譯器攔下。
**「Web 建置成功」不等於「全部程式碼都被編譯過」**——
未被入口點可達的程式路徑不一定會被完整檢查。

已新增 **T9** 靜態檢查涵蓋這一類。

### 新增檢查 T8

`const` 集合的元素型別不得覆寫 `==`（`const_set_element_type_implements_equals`）——
常數集合必須在編譯期去重，而自訂 `==` 編譯期算不出來。

這類錯誤只有編譯器抓得到，而且很容易寫出來。已補進 `typecheck.py`。

### 檢查器演進紀錄

| 輪次 | 檢查項 | 變異測試 | 觸發原因 |
|---|---|---|---|
| 第二輪 | T1–T7 | 6/6 | 無法編譯，自建型別檢查 |
| 第三輪 | +T8 | 6/6 | macOS 實測發現 const 集合錯誤 |
| 第四輪 | +T9 | **7/7** | macOS 實測發現 const 引數錯誤 |

每一個新檢查都來自真實環境的失敗回饋，而不是憑空想像的規則。

## 第四輪：harness 收斂（2026-08-13）

| 編號 | 問題 | 根因 | 修正 |
|---|---|---|---|
| M-8 | `scrollUntilVisible` 拋 `Bad state: Too many elements` | 每個 `TextField` 內部都有一個 `Scrollable`，表單有六個輸入框 → finder 找到七個 | 改用 `dragUntilVisible` 並明確指定 `find.byType(ListView)` |
| M-9 | `use_build_context_synchronously` ×2 | `await` 之後才用 `context`，只檢查 `State.mounted` 並不足夠 | 在 `await` 之前先取出 `GoRouter.of(context)` |
| M-10 | 21 個檔案有格式 diff | `dart format` CLI 預設 80 欄，程式碼照 90 欄寫 | `analysis_options.yaml` 加 `formatter: page_width: 90` |
| M-11 | `build_web` 略過 | `verify_demo.sh` 寫成「三平台全缺才建」，只缺 web 時不會補 | 改為逐一檢查、缺哪個補哪個 |
| M-12 | 18 個 `require_trailing_commas` | **工具鏈衝突**：Dart 3.7 tall-style 格式化器會移除尾隨逗號，lint 卻要求加上 | 停用該 lint，理由記於 `docs/COMPAT.md` |

### M-12 的判斷過程值得記錄

現象很奇怪：`dart format` 通過，但 analyze 抱怨 18 處缺少尾隨逗號。
格式化器與 lint 對同一份程式碼給出相反的要求。

查證後確認是已知衝突（`dart_style#1652`、`sdk#61338`）：新格式化器接管了換行決策，
而尾隨逗號原本的用途正是手動控制換行。

**遇到「工具 A 通過但工具 B 不通過同一份程式碼」時，先確認兩者是否本來就衝突，
而不是急著改程式碼去滿足兩邊 —— 那是滿足不了的。**

## 第五輪：接上真實後端（2026-08-13）

| 編號 | 嚴重度 | 問題 | 修正 |
|---|---|---|---|
| M-13 | BLOCKER | `supabase_flutter` 轉出的 gotrue `Session` 與 domain 的 `Session` 撞名，測試與 web 建置雙雙失敗 | 全面改用 `as sb` 前綴；新增 **T10** 檢查 |
| M-14 | BLOCKER（設計缺口） | `crews_public_read` 只允許讀 `published`，團長送出後自己的後台看不到資料 | `0005_owner_visibility.sql` 補上 owner 讀取政策 |

### M-13 的錯誤訊息很有誤導性

```
Error: 'Session' is imported from both 'package:gotrue/...' and 'package:joincrew/...'
import '../domain/entities.dart';
^^^^^^^
```

箭頭指向 **domain 的 import 行**，但那一行完全沒問題——
真正該改的是上面那行第三方 import。這類訊息很容易讓人往錯的方向修。

T10 的訊息直接說出真正的原因與解法，這是自建檢查器相對於編譯器的少數優勢：
**可以針對專案的具體情境給出可執行的建議，而不是通用的語言層描述。**

### M-14 只有跑過完整讀寫流程才會發現

RLS policy 單獨看每一條都正確，但組合起來少了一個情境：
使用者讀自己的未發布資料。光審視 SQL 看不出來，
必須實際走一次「送出 → 回到後台」才會浮現。

### 檢查器演進紀錄（更新）

| 輪次 | 檢查項 | 變異測試 | 觸發原因 |
|---|---|---|---|
| 第二輪 | T1–T7 | 6/6 | 無法編譯，自建型別檢查 |
| 第三輪 | +T8 | 6/6 | macOS 實測：const 集合錯誤 |
| 第四輪 | +T9 | 7/7 | macOS 實測：const 引數錯誤 |
| 第五輪 | +T10 | **8/8** | macOS 實測：第三方套件撞名 |

## 第六輪：analyze 收斂

| 編號 | 問題 | 修正 |
|---|---|---|
| M-15 | `profile_screen` 有未使用的 import | 移除；新增 **C9** 檢查 |
| M-16 | `refresh()` 沒 await，提示會比畫面更新早出現 | 加 `await` |
| M-17 | `anonKey` 已淘汰（2026 年底停用） | 改用 `publishableKey`，兩個環境變數都接受 |

### C9 的取捨

第一版 C9 一跑就噴 22 個誤判——只抓了 class，漏掉頂層函式（`sportIcon`）
與無型別的 `final`（`adminProvider`）。修正抓取範圍後歸零。

但更重要的判斷是**把它降為 MINOR 而非 BLOCKER**：
`flutter analyze` 的 `unused_import` 才是權威，我的版本只是在沒有 analyzer
的環境提供早期提示。**用自製工具去複製一個既有工具做得更好的事，
只會製造噪音。** 自建檢查器的價值在補足空白，不在重疊。

## 第七輪：改名與 T-070 實作

| 編號 | 問題 | 修正 |
|---|---|---|
| M-18 | `smoke_test` 硬編 `'JoinCrew'` 字面值，改名即壞 | 改用 `s.appName` |
| M-19 | `selfcheck.py` / `typecheck.py` 寫死 `package:joincrew/`，改名後噴 81 個假警報 | 改為從 `pubspec.yaml` 讀取 |
| M-20 | `crews_search_idx` 用 `to_tsvector('simple')`，**不會斷中文詞** | 改用 `pg_trgm` 三元組相似度 |

### M-18 的意義

「widget 中不得硬編使用者可見字串」這條規則，**連測試也適用**。
測試裡寫 `find.text('JoinCrew')` 看起來無害，但它讓改名這件事
從「改一個常數」變成「找出所有散落的字面值」。

### M-19：檢查器自己也會腐爛

寫死套件名稱的後果特別嚴重：失敗訊息是 81 個「未 import 的型別」，
完全看不出真因是改名。**基礎設施的錯誤訊息品質，比功能程式碼更重要**——
功能壞了你知道要看哪裡，工具壞了你會先懷疑自己。

### M-20：只有寫搜尋功能才會發現的缺陷

Postgres 的 `to_tsvector('simple')` 不斷中文詞，整串當一個 token，
所以搜「夜跑」找不到「信義夜跑團」。這個索引從 `0001_init.sql` 就存在，
但在實作搜尋之前完全不會被觸發。

**規格驅動的價值在這裡：** T-070 的 Scenario 逼出了一個
存在已久但沒人發現的後端缺陷。

## 第八輪：T-076 與檢查器的兩個盲點

| 編號 | 嚴重度 | 問題 | 修正 |
|---|---|---|---|
| M-21 | **BLOCKER** | `discovery_screen` 呼叫 `locationForFilter()`，但該函式在 `router.dart` 且未被 import。**所有檢查全綠、卻編譯失敗** | 把行為移進 `CrewFilter.toLocation()`；C4 擴充到頂層函式 |
| M-22 | BLOCKER | `spec_coverage.sh` 在 macOS 報 `id?: unbound variable` | 整支改寫為 `spec_coverage.py` |
| M-23 | MINOR | C9 把字串內插中的 `TimeFormatter` 判為未使用 | 改掃原始碼而非 strip 過的版本 |

### M-21：檢查器最嚴重的一種失敗

C4 原本只索引 class / enum / mixin / extension，**不含頂層函式**。
所以呼叫一個未 import 的頂層函式時，八項檢查全數通過，
卻在 `flutter test` 才炸——而且錯誤同時出現在兩個看似無關的測試檔，
很難第一眼看出真因。

**「檢查通過」給人的信心，正比於檢查的涵蓋範圍。**
涵蓋範圍有洞而不自知，比沒有檢查更危險。

修正時同時做了兩件事：
1. C4 索引頂層函式（並用變異測試驗證）
2. 把 `locationForFilter` 移進 `CrewFilter.toLocation()`——
   它本來就是 CrewFilter 的行為，放在 router 才造成跨層依賴。
   **正確的分層讓這個錯誤不可能發生**，比事後檢查更根本。

收斂誤判時也學到：頂層符號不能收「變數」，只能收「函式」。
`final router = GoRouter.of(context)` 這種區域變數會與頂層名稱撞名。

### M-22：第三次被 shell 咬

前兩次是 BSD sed/grep 不支援 `\s`。這次是 bash 3.2 在非 UTF-8 locale 下
把 `$id（` 的高位元組吃進變數名，報成 `id?: unbound variable`——
訊息完全看不出真因。

**含 CJK 的檢查腳本一律用 Python。** 這條現在寫進 `CLAUDE.md`。

## 第九輪：測試污染——全域可變單例

| 編號 | 嚴重度 | 問題 | 修正 |
|---|---|---|---|
| M-24 | **BLOCKER** | `router` 是頂層單例，導覽位置全 process 共用。測試**單獨跑會過、一起跑會失敗** | 改為 `routerProvider`；新增 **C10** 檢查 |

### 診斷過程值得記錄

前兩輪我在只看到 stack trace 尾巴的情況下推論，修了兩個真實但無關的問題
（EmptyStateView 橫向溢位、測試視窗尺寸）。第三輪才要到關鍵資訊：

```
flutter test --plain-name "沒有結果時顯示空狀態文案"   → All tests passed!
flutter test --plain-name "點卡片可導覽到詳情頁"       → All tests passed!
```

**單獨跑都過、一起跑失敗** —— 這個訊號直接指向共用狀態，
而且比任何 stack trace 都精確。

### 根因

```dart
final router = GoRouter(initialLocation: '/', ...);   // 頂層單例
```

目前位置存在 router 裡面。搜尋測試呼叫 `context.replace('/?q=...')` 之後，
那個位置留了下來，後面每個測試 boot 起來就已經停在被篩空的列表上。

**這不只是測試問題。** 全域可變狀態意味著同一個 process 內的所有 App 實例
共用導覽歷史——hot restart、多視窗、整合測試都會受影響。

改成 `Provider` 之後每個 `ProviderScope` 各自持有，並在 `onDispose` 釋放。
**這不是為了測試而做的妥協，是全域可變狀態本來就該避免。**

### 教訓

「單獨跑會過、一起跑會失敗」是共用狀態的特徵訊號。
遇到測試失敗時，**先試單獨跑一次**——它能在三十秒內把問題分成兩類，
比讀 stack trace 快得多。

新增檢查 C10 涵蓋這一類（列舉已知會持有狀態的型別，避免噪音），
並加了回歸測試 `NoGlobalNavState`：連續啟動兩次 App，第二次必須是乾淨的。

## 尚未覆蓋（誠實列出）

- Golden test（視覺回歸）——需要先在 Mac 上產基準圖
- 整合測試（`integration_test/`）——需要模擬器
- `CrewListController` 的競態與 debounce——需要 `fake_async` 套件
- RLS 滲透測試——需要真實 Supabase 實例
- LINE 登入端到端——需要真實 channel
