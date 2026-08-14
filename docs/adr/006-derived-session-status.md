# ADR-006：活動狀態用推導，不存欄位

狀態：Accepted　日期：2026-08-12

## 背景
活動有 scheduled / imminent / ongoing / past 四種狀態，UI 需要據此分區與強調。

## 決策
`sessions` 表**不存 status 欄位**。狀態由 `starts_at`、`ends_at` 與當前時間
以純函式 `Session.statusAt(now)` 推導。

## 理由
存欄位就需要排程去翻轉它。而排程會遲到、會漏、會在時區邊界出錯——結果是
「已結束的活動還顯示即將到來」，這是使用者最無法容忍的錯誤之一。
推導式狀態永遠正確，且是純函式，100% 可單元測試。

## 代價與緩解
- 不能對 status 建索引 → 用 `where starts_at > now()` 的**部分索引**解決。
- 需要在多處呼叫推導函式 → 收斂成單一 `statusAt`，並注入 Clock 讓它可測。

## 相關
- test/unit/session_status_test.dart（含跨午夜案例）
- supabase/migrations/0001_init.sql 的 `sessions_upcoming_idx`
