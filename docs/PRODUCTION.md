# 開放真實使用者前的檢查清單

**技術上，這個專案現在就能接受真實使用者的寫入。** 寫入路徑不經過 GitHub Pages：

```
使用者按下「送出社團」
   │
   └─▶ 瀏覽器直接 POST 到 Supabase
         ├─ Auth 驗證 JWT：你是誰？
         ├─ RLS 檢查：你能寫這一列嗎？
         └─ 寫入 Postgres
```

但「技術上做得到」和「應該開放」是兩件事。
一旦有真實使用者，你就從寫作品集變成經營服務，多出一整套義務。

這份清單分四級。**做完 P0 才可以放上真實使用者。**

---

## P0 — 不做就不要開放

### ☐ 資料備份

免費方案的備份保留是**零天**。誤刪一張表、migration 寫錯、
專案暫停後還原異常 —— 資料就沒了，而那是別人的資料。

專案已附 `.github/workflows/backup.yml`，每天 `pg_dump` 一次存成 artifact。

**還原演練也要做一次。** 沒有測試過的備份不算備份：

```bash
gunzip -c backup-20260813-1800.sql.gz | psql "$LOCAL_DB_URL"
```

### ☐ RLS 已啟用且驗證過

`0002_rls.sql` 已經寫好，但**部署後要實際驗證一次**，不能只相信 SQL 寫對了：

```bash
# 拿 anon key 直連，試著做不該做的事，每一項都應該失敗
curl -X PATCH "$SUPABASE_URL/rest/v1/crews?id=eq.某個ID" \
  -H "apikey: $ANON_KEY" -H "Content-Type: application/json" \
  -d '{"activity_score": 9999}'
# 預期：401 或 0 rows affected

curl "$SUPABASE_URL/rest/v1/crews?status=eq.pending" \
  -H "apikey: $ANON_KEY"
# 預期：空陣列（未發布的社團不可見）

curl "$SUPABASE_URL/rest/v1/submissions" -H "apikey: $ANON_KEY"
# 預期：401（submissions 表未開放讀取）
```

三項全部如預期，才算 RLS 真的生效。

### ☐ 審核佇列有人看

`submit_crew()` 寫入的 `status` 是 `pending`，不會自動發布 —— 這是刻意的。
但**如果沒有人去審，使用者送出後就石沉大海**，比不開放更糟。

最低限度：Supabase Dashboard 加一個 SQL 檢視，你每天看一次。
或用 Database Webhook 在有新送出時發 email 給自己。

### ☐ 隱私權政策與服務條款

一旦蒐集 LINE 顯示名稱與大頭貼，就進入台灣《個人資料保護法》的適用範圍。
你需要明確告知：蒐集什麼、目的為何、保存多久、如何刪除。

App 內至少要有：

- 隱私權政策頁面（登入前可讀）
- 「刪除我的帳號與資料」的實際功能，不是只寫在條款裡
- 聯絡方式

登入畫面已經有誠實揭露的文案（「只會取得顯示名稱與大頭貼」），
但那是善意，不等於法律上的告知義務已盡。

### ☐ 內容處理機制

真實使用者會送出：測試資料、重複社團、廣告、以及偶爾的惡意內容。

- 已有：honeypot、`idempotency_key` 防重複、審核佇列
- **還缺：檢舉機制、下架流程、被拒絕時的通知**

---

## P1 — 開放後兩週內補上

### ☐ 速率限制

目前 `submit_crew()` 沒有任何頻率限制。一個腳本可以在一分鐘內灌爆審核佇列。

Supabase 的做法是在 RPC 內檢查同一 `auth.uid()` 或 IP 的近期次數：

```sql
-- 在 submit_crew() 開頭
if (select count(*) from submissions
    where created_at > now() - interval '1 hour'
      and payload->>'_uid' = auth.uid()::text) >= 3 then
  raise exception 'rate_limited';
end if;
```

### ☐ 錯誤監控

沒有監控就等於瞎著跑。使用者不會回報錯誤，他們只會離開。

Sentry 免費方案（每月 5000 筆事件）足夠：

```yaml
dependencies:
  sentry_flutter: ^8.0.0
```

### ☐ 後端不可用時的降級

`FakeCrewRepository` 隨時可用。讓 `SupabaseCrewRepository` 在連線失敗時
降級到本地資料，頂端標示「示範資料」。

Supabase 免費方案 7 天無活動會暫停 —— 有降級的話，
就算被暫停也不會變成白畫面。

### ☐ 資料庫容量監控

免費方案 500 MB。含圖片的話會比你想像的快用完。

```sql
select pg_size_pretty(pg_database_size(current_database()));
```

---

## P2 — 規模變大時

- **50,000 MAU** 是免費方案上限
- **Supabase Pro 每月 25 美元**：移除暫停、每日備份、更大配額
- 圖片改走 Cloudflare Images 或 R2，不要放 Supabase Storage（1 GB 上限）
- 讀取量大時在 PostgREST 前加快取層

---

## P3 — 這個專案特有的風險

### ☐ 與 joindui.tw 的關係

專案概念參考自該站。作為**技術學習專案**沒有問題，README 也已聲明無隸屬關係。

但**如果你開始接受真實社團的資料、變成實際運作的服務**，
性質就從「致敬」變成「競爭」。這時要注意：

- 不要使用對方的商標、視覺、文案
- 不要抓取對方的資料庫內容
- 社團名稱與資訊應由該社團自己送出，或取得授權

目前的合成資料全部是虛構的，這點要維持到你有真實授權為止。

### ☐ 真實社團的名譽

活躍度積分是公開排序。如果真實社團被排在後面，那是對他們的公開評價。
評分規則必須透明（已有積分明細）、可申訴（**還沒有**）。

---

## 我的建議

**先不要開放真實使用者。**

理由不是技術不足，而是投入產出比。你的目標是轉職 Flutter，
而面試官在意的是「你能不能設計並實作一個有品質的系統」——
這件事你已經做到了，開放真實使用者不會讓這個結論更成立。

反而會帶來：審核工作、客服、法遵、資料保管責任，
每一項都在消耗你本來該拿去寫程式、準備面試的時間。

### 更划算的中間方案

用**合成資料 + 完整可寫功能**上線：

- 任何人都能註冊、登錄社團、新增活動 —— 功能完全真實
- 資料是虛構的，且每晚重置（一支 GitHub Actions cron 即可）
- 首頁明確標示「這是技術展示專案，資料為虛構」

面試官可以完整體驗整個流程、可以自己送出一個社團看流程跑完，
而你不承擔任何真實資料的責任。

**你要展示的是能力，不是營運一個平台。**

真的想做成產品，那是另一個決定，值得單獨規劃 ——
到那時再回來看這份清單的 P0。
