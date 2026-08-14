---
description: 依 spec 實作一個 task，並自動迴圈直到 harness 全綠
---

讀取 `docs/tasks/$1.spec.md`，依 `touches` 白名單載入相關檔案，
以 engineer 角色實作。

完成後執行 `bash tool/harness.sh`。

收斂規則：
- failed blocker 數嚴格遞減 → 繼續下一輪
- 連續兩輪失敗項目集合相同 → 判定震盪，停止並輸出診斷
- 本輪失敗數 > 上輪 → 回滾，改用更小的步驟
- 輪數 > 5 → 停止，保留分支給人接手
- 若判斷是規格本身矛盾 → 標記 spec_defect 並回到 architect

每一輪只把「原始 spec + 當前 diff + 本輪失敗項與最後 40 行輸出 +
上輪無效的方向」傳入，不要把全部歷史塞回去。
