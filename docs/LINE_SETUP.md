# LINE 登入設定步驟

**前提：必須先有 Supabase 專案。** channel secret 不能進前端，
token 交換一定要在 Edge Function 執行。這條依賴躲不掉。

---

## Step 1 — Supabase 專案

```bash
# supabase.com 建立專案後
supabase link --project-ref <你的 project ref>
supabase db push                          # 套用 10 支 migration
psql "$DB_URL" -f supabase/seed.sql       # 25 個虛構社團
```

Dashboard → Authentication → Providers → 開啟 **Anonymous sign-ins**
（不開的話匿名登入會回 422）。

## Step 2 — LINE Channel

到 <https://developers.line.biz/console/>：

1. 建立 **Provider**（例如「JoFormosa」）
2. 在該 Provider 下建立 **LINE Login channel**（不是 Messaging API）
3. **LINE Login 分頁** → 確認 **Web app** 已啟用 → Callback URL 填：

```
https://josephtsengd.github.io/joformosa/auth/line
```

⚠ **完全一致,包含 base-href 前綴。** 少一個斜線 LINE 就拒絕，
而且錯誤訊息不會告訴你差在哪。本機開發要另外加一行
`http://localhost:5555/auth/line`（可以填多個）。

4. **Basic settings 分頁** 記下 **Channel ID** 與 **Channel secret**

### 兩個會卡住你的細節

**① Channel 預設是 Developing 狀態。** 只有 Admin / Tester 角色的人能登入。
你自己測沒問題，面試官點下去會失敗。要按 **Published** 才對外開放。

**② 不要申請 email scope。** 本專案只用 `openid profile`，那兩個不需要審核。
`email` 要送出申請並附截圖，通常 1–2 個工作天，而我們根本用不到。

## Step 3 — 部署 Edge Function

```bash
supabase functions deploy line-auth --no-verify-jwt
supabase secrets set \
  LINE_CHANNEL_ID=你的ChannelID \
  LINE_CHANNEL_SECRET=你的ChannelSecret
```

`--no-verify-jwt` 是必要的：使用者在交換 token 時**還沒有** Supabase session，
帶不出 JWT。

驗證有部署成功：

```bash
supabase functions list
```

⚠ **channel secret 只存在這裡。** 不進 git、不進 dart-define、不進前端。

## Step 4 — 前端設定

本機：

```bash
flutter run -d chrome --web-port 5555 \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx \
  --dart-define=LINE_CHANNEL_ID=2000000000 \
  --dart-define=LINE_REDIRECT_URI=http://localhost:5555/auth/line
```

`--web-port 5555` 要固定，否則每次跳號都與註冊的 Callback URL 對不上。

GitHub Actions：Settings → Secrets 新增

```
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
LINE_CHANNEL_ID
LINE_REDIRECT_URI = https://josephtsengd.github.io/joformosa/auth/line
```

並在 `deploy-web.yml` 的 build 步驟加上對應的 `--dart-define`。

---

## 流程與安全設計

```
  App                      Edge Function            LINE
   │  ① 整頁跳轉 authorize   │                        │
   ├────────────────────────────────────────────────▶│
   │  ② 導回 /auth/line?code │                        │
   │◀────────────────────────────────────────────────┤
   │  ③ POST {code,verifier} │                        │
   ├────────────────────────▶│  ④ code + secret       │
   │                         ├───────────────────────▶│
   │                         │  ⑤ id_token            │
   │                         │◀───────────────────────┤
   │  ⑦ tokenHash            │  ⑥ verify 驗簽 + 建帳號  │
   │◀────────────────────────┤                        │
   │  ⑧ verifyOTP → session  │                        │
```

| 機制 | 防什麼 |
|---|---|
| **PKCE (S256)** | 授權碼被攔截後無法使用——沒有 verifier 換不到 token |
| **state** | CSRF。不比對的話，攻擊者可誘導你的瀏覽器帶著**他的** code 回來，結果你登入了他的帳號 |
| **nonce** | id_token 重放 |
| **secret 只在 Edge Function** | 反編譯 / DevTools 都拿不到 |
| **用 LINE 的 verify endpoint 驗簽** | 直接 base64 decode id_token 就信任，等於沒有驗證 |

`state` 與 `verifier` 存在 SharedPreferences 而非記憶體——
web 是**整頁跳轉**，回來時是全新的 App 實例，記憶體中的變數早就沒了。

---

## 疑難排解

| 現象 | 原因 |
|---|---|
| `400 invalid_request` | Callback URL 與註冊的不一致（含斜線、含 base-href） |
| `400 invalid_grant` | code_challenge 帶了 base64 padding 的 `=`，或 verifier 對不上 |
| 只有你自己登得進去 | Channel 還在 Developing，要 Published |
| 畫面顯示「找不到進行中的登入流程」 | 使用者直接貼了 callback 網址，或跨瀏覽器操作 |
| Edge Function 回 401 | secrets 沒設，或部署時漏了 `--no-verify-jwt` |

## 尚未涵蓋

- **行動裝置的 OAuth 流程**（T-086）。web 走整頁跳轉，
  App 需要 `flutter_web_auth_2` 開系統瀏覽器並註冊 URL scheme。
- **匿名帳號升級保留收藏**。目前 `linkLine()` 與 `signInWithLine()` 走同一條路，
  升級時會換成新的 user id。收藏存在本地所以看不出來，
  但接上雲端同步後必須處理。
