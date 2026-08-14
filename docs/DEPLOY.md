# 把 JoinCrew 放到網路上

Flutter web build 出來是**純靜態檔案**（HTML / JS / WASM / 圖片），沒有伺服器端程式。
理解這件事就能理解為什麼下面的建議是這樣排的。

---

## 先做決定

| 方案 | 費用 | HTTPS | 自訂網域 | 適合 |
|---|---|---|---|---|
| **GitHub Pages** | 免費 | ✅ 自動 | ✅ | **面試作品集，首選** |
| **Cloudflare Pages** | 免費 | ✅ 自動 | ✅ | 需要 SPA rewrite、預覽部署 |
| **Firebase Hosting** | 免費額度 | ✅ 自動 | ✅ | 之後想加 Cloud Functions |
| **家用網路 + Cloudflare Tunnel** | 免費 | ✅ 自動 | 需自備網域 | 學習、內部工具 |
| **家用網路 + 通訊埠轉發** | 免費 | 要自己弄 | 需自備網域 | ❌ 不建議 |

**如果你的目的是給面試官看：用 GitHub Pages。** 程式碼本來就要放 GitHub，
推上去就自動部署，網址還能直接寫進履歷。

家用網路不是不行，而是你會換來一組不對等的代價：
斷電就掛、動態 IP、上傳頻寬通常只有下載的十分之一、
而且台灣多數家用方案（含中華電信部分方案）對外連入的 80 / 443 是封鎖或走 CGNAT 的。

---

## 方案一：GitHub Pages（建議）

專案已附 `.github/workflows/deploy-web.yml`，推上去就會自動建置部署。

```bash
cd joincrew
git init
git add -A
git commit -m "feat: JoinCrew Flutter portfolio project"
gh repo create joincrew --public --source=. --push
```

然後到 GitHub 儲存庫 → **Settings → Pages → Source 選 `GitHub Actions`**。

推上 `main` 之後約三分鐘，網址是：

```
https://<你的帳號>.github.io/joincrew/
```

### workflow 裡三個非做不可的步驟

這三件事漏掉任何一個，部署都會「成功」但網站是壞的 —— 而且錯誤訊息完全不會告訴你原因。

**① `--base-href /joincrew/`**

GitHub Pages 的專案站台不在網域根目錄。不設 base-href 的話，
`index.html` 會去 `/main.dart.js` 找檔案，但實際位置是 `/joincrew/main.dart.js`。
結果是白畫面，Console 一堆 404。

**② 把 `index.html` 複製成 `404.html`**

這是 SPA 部署最常見的坑。使用者直接開 `https://.../joincrew/crews/dawn-0`
（例如你把連結貼給面試官），伺服器去找 `crews/dawn-0` 這個檔案，找不到就回 404。

GitHub Pages 沒有 rewrite 規則，但它找不到檔案時會送 `404.html`。
所以把 `index.html` 複製一份叫 `404.html`，Flutter 就會正常啟動，
再由 go_router 讀取網址、顯示正確的社團。

**深連結是這個專案的賣點之一，沒做這步等於自廢武功。**

**③ 建立 `.nojekyll`**

GitHub Pages 預設跑 Jekyll，而 Jekyll **會忽略底線開頭的檔案與資料夾**。
Flutter 的 canvaskit 資源就在那裡面。少了這個空檔案，網站會在載入時卡住。

---

## 方案二：Cloudflare Pages

比 GitHub Pages 多兩個好處：每個 PR 自動產生預覽網址，以及真正的 SPA rewrite
（不用靠 404.html 這種變通做法）。

```bash
cp deploy/_redirects web/_redirects    # /* /index.html 200
```

然後在 Cloudflare Dashboard → Workers & Pages → Create → Connect to Git：

| 欄位 | 值 |
|---|---|
| Build command | `flutter build web --release` |
| Build output directory | `build/web` |
| Environment variable | `FLUTTER_VERSION` = `stable` |

Cloudflare Pages 的建置環境沒有內建 Flutter，需要在 build command 前面
先下載。比較省事的做法是沿用 GitHub Actions 建置，再用
`cloudflare/pages-action` 上傳產物。

---

## 方案三：家用網路 + Cloudflare Tunnel

如果你就是想用家裡的機器 —— **這是唯一我會建議的做法**，不要開通訊埠轉發。

### 為什麼不用通訊埠轉發

傳統做法是路由器把 80 / 443 導進你的電腦。問題是：

- **等於把家用網路直接暴露在公網上。** 你家所有裝置（NAS、印表機、監視器）
  都在同一個內網。一個設定失誤就是全家中獎。
- **你的住家 IP 會被公開。** 任何訪客都看得到。
- **台灣家用方案多半擋 80 / 443 連入，或走 CGNAT**（多戶共用一個公網 IP），
  後者根本無法轉發 —— 你連自己的路由器都沒有公網位址。
- **動態 IP。** 重開機換一次 IP，網域就指錯地方，要另外弄 DDNS。
- **憑證要自己申請與續期。**

### Cloudflare Tunnel 怎麼解決

你的機器主動**向外**建立一條持久連線到 Cloudflare。
外部流量走這條既有連線回到你家。

因此：**不用開任何通訊埠、不用公網 IP、CGNAT 也能用、HTTPS 自動處理、
還附帶 Cloudflare 的 DDoS 防護。** 連接器本身與流量都是免費的。

### 步驟

需要一個網域（`.com` 約每年 10 美元），並把 DNS 轉到 Cloudflare。

```bash
# 1. 建置與本機伺服器
cd joincrew
flutter build web --release
brew install caddy
caddy run --config deploy/Caddyfile      # 先把 Caddyfile 的網域改成 :8080

# 2. 另一個終端機分頁：安裝並登入 cloudflared
brew install cloudflared
cloudflared tunnel login                  # 瀏覽器會開起來，選你的網域

# 3. 建立通道並指向本機服務
cloudflared tunnel create joincrew
cloudflared tunnel route dns joincrew joincrew.你的網域.com
cloudflared tunnel run --url http://localhost:8080 joincrew
```

開 `https://joincrew.你的網域.com` 就會看到網站。

Cloudflare 現在也支援在儀表板上遠端管理通道（Zero Trust → Networks → Tunnels），
設定存在雲端、本機只需要一組 token，省去維護本地 config 的麻煩。

### 讓它開機自動啟動

```bash
sudo cloudflared service install     # 註冊成 launchd 服務
```

Caddy 也要一起：`brew services start caddy`。

### 家用自架的真實代價

即使用了 Tunnel，這些仍然存在：

- **停電、重開機、Mac 睡眠 → 網站掛掉。** 面試官剛好那時點開就沒了。
- **上傳頻寬是瓶頸。** 台灣家用方案常見 300M/100M，上傳只有下載的三分之一。
- **電費與機器折舊。** 一台 Mac 全年不關機不是零成本。
- **部分 ISP 的服務條款禁止家用線路架設對外服務。** 用之前看一下合約。

所以我的建議還是：**GitHub Pages 放正式作品，家用 Tunnel 拿來學習或臨時分享。**
兩者不衝突，同一份 `build/web` 都能用。

---

---

## 後端要放哪？（GitHub Pages 只放前端）

一個常見的誤解是「GitHub Pages 不能接 API，所以不能有後端」。
實際上前端與後端本來就是分開部署的：

```
使用者瀏覽器
   │
   ├─ ① 下載靜態檔案 ──────────▶ GitHub Pages
   │
   └─ ② fetch / XHR 打 API ───▶ Supabase（Postgres + Auth + Edge Functions）
```

GitHub Pages 不需要知道 Supabase 存在，Supabase 也不需要知道前端放哪。
瀏覽器載入 JS 之後，是**瀏覽器自己**去打 API。這就是 JAMstack。

本專案從一開始就是照這個架構設計的：`supabase/migrations/` 的四支 SQL、
RLS 政策、`crews_with_next_session` RPC、LINE 登入的 Edge Function ——
那些全部都是後端，只是還沒部署。

### 各項需求對應到哪裡

| 需求 | 靜態託管做得到嗎 | 這個專案的做法 |
|---|---|---|
| 讀取社團／活動資料 | ✅ 瀏覽器直接打 PostgREST | `crews_with_next_session` RPC |
| 使用者登入 | ✅ Supabase Auth | 匿名 + LINE |
| 授權（誰能改什麼） | ✅ 由資料庫執行 | RLS 政策（`0002_rls.sql`） |
| **需要保密金鑰的操作** | ❌ 客戶端一律不可信 | **Edge Function**（`line-auth`） |
| 排程工作（每週算積分） | ❌ | `pg_cron` + `recompute_scores()` |
| SEO／首屏 SSR | ❌ 靜態託管做不到 | 需要預渲染，見下方 |

**分界線很清楚：任何需要密鑰的動作都必須在伺服器端。**
LINE 的 channel secret 放進 App 就等於公開（反編譯即可取得），
所以它只存在於 Edge Function —— 這是 `docs/adr/007` 的核心論點。

### anon key 放在前端沒問題嗎？

會問這題代表你抓到重點了。答案是：**沒問題，而且是設計如此。**

- `anon key` 本來就是公開的，它只表示「我是匿名訪客」
- 真正的安全邊界是 **RLS**：即使有人拿 anon key 直連 PostgREST，
  也只能讀到 `status = 'published'` 的資料，改不了任何東西
- `0002_rls.sql` 裡的 `with check` 甚至阻止團長修改自己的積分

**絕對不能放進前端的是 `service_role` key** —— 那把鑰匙會繞過所有 RLS。
它只能存在於 Edge Function 的環境變數。

面試時這是很好的追問點：「你怎麼確定前端被繞過還是安全的？」
答案是把授權下沉到資料層，而不是靠前端隱藏按鈕。

### CORS

Supabase 的 PostgREST 預設允許所有來源，GitHub Pages 直接打不需要額外設定。
自架 API 的話記得在回應加上 `Access-Control-Allow-Origin`。

---

## ⚠ Supabase 免費方案會在 7 天無活動後暫停

這是免費方案最容易踩的坑，對作品集網站尤其致命：
面試官點開時剛好是第 8 天，資料庫是關的，網站一片空白。

- 暫停 ≠ 刪除，資料還在，但 Dashboard 要手動按 restore
- 暫停期間 `pg_cron` 停止，Edge Function 也連不上
- 免費方案**沒有備份保留**，所以不要把唯一的資料放在上面

### 解法：keep-alive

專案已附 `.github/workflows/keep-alive.yml`，每 3 天打一次最輕量的查詢。
設定兩個 secret 即可（Repo → Settings → Secrets and variables → Actions）：

```
SUPABASE_URL       https://xxxxx.supabase.co
SUPABASE_ANON_KEY  匿名金鑰
```

用 3 天而非 6 天，是為了留出排程延遲與失敗重試的緩衝。
查詢失敗時 workflow 會紅燈通知你，而不是靜靜地失效。

### 更穩的做法：保留 Fake 資料層作為降級

這個專案有個天然優勢：`FakeCrewRepository` 隨時可用。

正式部署時可以讓 `SupabaseCrewRepository` 在連線失敗時降級到 Fake 資料，
畫面頂端顯示「示範資料」提示。這樣即使後端掛了，**demo 永遠有東西可看**。

面試時這反而是加分項：「你怎麼處理後端不可用？」
——「降級到本地資料並明確告知使用者，而不是給白畫面。」

---

## 要開放真實使用者嗎？

技術上做得到——寫入走 `瀏覽器 → Supabase`，GitHub Pages 不在路徑上。
但那會讓你從「寫作品集」變成「經營服務」，多出備份、審核、法遵、客服等義務。

完整清單見 [`docs/PRODUCTION.md`](PRODUCTION.md)。
簡短版：**建議用合成資料 + 完整可寫功能上線**，功能全真、資料虛構、每晚重置。
面試官能完整體驗流程，你不承擔真實資料的責任。

---

## SEO 與首屏

靜態託管無法做伺服器端渲染。爬蟲拿到的是空的 `index.html`。

對面試作品集來說這**通常不重要**。真的需要的話：

1. Cloudflare Workers 在 edge 判斷 User-Agent，對爬蟲回傳預先產生的 HTML
2. 或改用支援 SSR 的框架（那就不是 Flutter web 了）

計劃書第 10 章有完整討論。Roadmap 也留了這一項。

---

## 部署後一定要驗證的四件事

不管用哪個方案，這四項都做一遍。**第 2 項是最常被漏掉的。**

```bash
# 1. 首頁能開，且不是白畫面
open https://你的網址/

# 2. 深連結：直接開子路徑（不是從首頁點進去）
open https://你的網址/crews/dawn-runners-0
#    白畫面或 404 → SPA fallback 沒設好（404.html 或 _redirects）

# 3. 重新整理不會壞
#    在詳情頁按 Cmd+R，還在同一頁才算對

# 4. 開發者工具 → Console 沒有紅色錯誤
#    有 404 → base-href 設錯
```

另外用手機開一次。Flutter web 在行動版 Safari 的字型 fallback 與桌面不同，
中文有機會變成方框。

---

## 效能：第一次載入會慢

Flutter web 的初次載入要下載 CanvasKit（約 1.5 MB）。改善方式：

```bash
# 用 HTML renderer，體積小很多，但複雜動畫效能較差
flutter build web --release --web-renderer html

# 或維持 canvaskit 但從 Cloudflare CDN 取用
flutter build web --release \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/
```

這個專案的 UI 以文字與版面為主，沒有複雜繪圖，**用 HTML renderer 是划算的**。
先量再改：`flutter build web --release --analyze-size`。
