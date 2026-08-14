# ADR-007：LINE Login 走 Edge Function 交換，不在 App 端換 token

狀態：Accepted　日期：2026-08-12

## 背景
台灣使用者的登入轉換率，LINE 遠高於 Google/Apple。但 Supabase Auth 沒有
內建 LINE provider。

## 選項
1. App 內直接呼叫 LINE token endpoint —— **否決**。需要 channel_secret，
   任何放進 App 的密鑰都能被反編譯取出。
2. 自架 OAuth proxy —— 成本過高。
3. **Supabase Edge Function 作為交換端點** —— 採用。

## 決策
App 只負責開系統瀏覽器走 authorize（帶 PKCE + state + nonce），拿到 code 後
POST 給 Edge Function；Function 持有 secret，換 token、**用 LINE verify
endpoint 驗證 id_token**、建立或取得 Supabase 使用者、簽發 session。

## 安全要點
- PKCE 防授權碼攔截（惡意 App 註冊同一個 URL scheme）
- state 在 App 端比對，防 CSRF
- nonce 寫進 id_token 並在 verify 時比對，防重放
- 絕不 base64 decode id_token 就信任——那等於沒驗證
- 匿名 → LINE 用 **link** 而非重新登入，確保既有收藏不遺失

## 相關
- supabase/functions/line-auth/index.ts
- lib/features/auth/data/line_auth_service.dart
