# 測試目錄

⚠ **`flutter create .` 會產生一個 `test/widget_test.dart` 樣板檔。**

它引用的是 `MyApp`（Flutter 預設計數器範例的類別），本專案沒有這個類別，
所以它一定會編譯失敗。**執行 `flutter create .` 之後請直接刪除它：**

```bash
rm -f test/widget_test.dart
```

本專案的入口測試是 `test/smoke_test.dart`，它啟動真正的 `JoFormosaApp`。
