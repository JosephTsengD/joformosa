---
description: 以獨立 context 審查一個 task
---

以 reviewer 角色審查 `$1`。

**只讀** spec、git diff、.harness/raw.jsonl。
不要讀取本次對話中 engineer 的任何說明——資訊隔離是這個流程的品質來源。

輸出寫入 `docs/reviews/$1.md`。
若有 BLOCKER 或 MAJOR，把 findings 傳回 /build 重做。
