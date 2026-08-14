# JoinCrew — 台灣運動社團探索 App

Flutter 三平台（Android / iOS / Web）單一程式碼庫。
離線優先、深連結可分享、支援團長自助上稿與 LINE 登入。

> **致敬與聲明**
> 本專案的產品概念參考自 [joindui.tw](https://joindui.tw)（揪隊）。
> 這是一個獨立的技術學習專案，與該站**無任何隸屬關係**。
> 所有資料為程式產生的合成資料，未使用其商標、視覺、文案或資料庫內容。

---

## 這個專案想證明什麼

給看 repo 的人的快速索引——每一項都對應一段可以被追問的技術決策：

| 主題 | 在哪裡看 |
|---|---|
| **推導式狀態**：活動狀態不存欄位，由時間推導 | `docs/adr/006` · `lib/.../entities.dart` · `test/unit/session_status_test.dart` |
| **資料庫層授權**：RLS + `with check` 防止團長改自己的積分 | `supabase/migrations/0002_rls.sql` |
| **N+1 的解法**：LATERAL JOIN 一次取回每團「下一場」 | `supabase/migrations/0003_rpc.sql` |
| **keyset 分頁**：不用 offset，資料變動不漏不重 | `crew_list_controller.dart` · `fake_repository_test.dart` |
| **五態 UI 建模**：sealed class + 窮盡 switch | `crew_list_state.dart` |
| **冪等性寫進 schema**：複合主鍵 + idempotency key | `0001_init.sql` · `submit_crew()` |
| **LINE 登入不外洩 secret**：Edge Function 交換 | `docs/adr/007` · `supabase/functions/line-auth` |
| **多角色 AI 工作流 + 機械化品質閘門** | `.claude/` · `tool/harness.sh` |

---

## 從零開始

1. **[`INSTALL.md`](INSTALL.md)** — 安裝 Flutter 環境（第一次接觸 Flutter 從這裡開始）
2. **[`RUNBOOK.md`](RUNBOOK.md)** — 建置、執行、測試、demo 腳本、疑難排解
3. **[`docs/TEST_AUDIT.md`](docs/TEST_AUDIT.md)** — 自我審查報告與已知風險
4. **[`docs/DEPLOY.md`](docs/DEPLOY.md)** — 部署上線（GitHub Pages / Cloudflare / 家用網路）
5. **[`docs/PRODUCTION.md`](docs/PRODUCTION.md)** — 開放真實使用者前的檢查清單

## 兩種執行模式

### 模式 A：合成資料（預設，零設定，且**完全可寫**）

```bash
flutter pub get
flutter run          # 或 flutter run -d chrome
```

`FakeCrewRepository` 提供 25 個虛構社團與約 150 場活動，包含**刻意植入的髒資料**
（無活動的社團、只有過往活動的社團、60 字超長名稱、缺 IG、跨午夜活動），
用來驗證 UI 韌性。固定 seed，每次執行結果相同。

**寫入功能是完整可用的。** 登錄社團、新增活動、收藏都會存進瀏覽器本地
（`LocalDraftStore`），重新整理後仍在。

為什麼不用「伺服器端每晚重置」？因為共用一份可寫資料庫時，
兩個訪客會互相看到對方的測試資料——面試官 A 送出「測試跑團 123」，
面試官 B 打開就看到它。改成本地儲存之後**每個訪客都有自己的沙盒**，
互不干擾，且零後端成本。「我的」頁面有「重置示範資料」可隨時回到初始狀態。

### 模式 B：真實 Supabase 後端

```bash
# 1. 取消 pubspec.yaml 中 supabase_flutter 的註解
# 2. 移除 lib/.../data/supabase_crew_repository.dart 的 /* */ 包裹
supabase start
supabase db reset          # 套用 migrations
cp env/dev.example.json env/dev.json    # 填入你的 URL 與 anon key
flutter run --dart-define-from-file=env/dev.json
```

兩個 repository 實作共用同一組 domain 契約——這就是 Repository 抽象層
不是裝飾品的證明。

---

## 專案結構

```
lib/
├─ app/          router · providers（DI 圖）· theme 組裝
├─ core/
│   ├─ theme/    Design Token（色彩 / 間距 / 字體）
│   ├─ utils/    Clock · Result · AppFailure · 格式化 · IdGen
│   ├─ l10n/     型別安全字典（zh-Hant / en）
│   └─ widgets/  跨 feature 共用元件
└─ features/
    ├─ crew_discovery/   domain · data · presentation（完整三層）
    ├─ crew_detail/
    ├─ crew_admin/       團長端：登錄 · 上稿
    ├─ auth/             匿名 · LINE 登入
    └─ favorites/
```

## 測試與品質閘門

```bash
bash tool/harness.sh          # 與 CI 完全相同的檢查
bash tool/harness.sh --fast   # 跳過建置
```

Harness 包含：格式 · 靜態分析 · **分層規則** · **反跳過測試** ·
單元測試 · **spec 覆蓋率**。exit code 就是「完成」的定義。

`tool/spec_coverage.sh` 是這套流程的關鍵：它解析 `docs/tasks/*.spec.md` 中
每一條 `Scenario:`，檢查 `test/` 裡是否有 `// @spec {id}/Scenario-{name}`
標記的測試。少一條就 fail——驗收條件與測試之間有機器可驗證的連結。

## AI 工作流

四個角色（architect / designer / engineer / reviewer）定義在 `.claude/agents/`。
關鍵設計是**資訊隔離**：reviewer 看不到 engineer 的推理過程，只讀 spec、diff
與 harness 結果，否則它會被「我已經處理了空狀態」這種自述錨定而略過驗證。

完整說明見計劃書第 11 章。

## Roadmap

- [x] 探索 · 篩選 · keyset 分頁 · 社團詳情 · 收藏
- [x] 團長端：社團登錄 · 活動上稿（含冪等與 honeypot）
- [x] LINE 登入流程與 Edge Function
- [ ] 圖片上傳管線（含 EXIF GPS 移除）
- [ ] 地圖檢視與距離排序（PostGIS）
- [ ] 本地通知提醒 · 加入行事曆
- [ ] Golden test 矩陣（亮/暗 × 3 字級 × 2 語言）
- [ ] Web SEO：edge 層 UA 分流回傳靜態 HTML

## License

MIT
