/// 表單反機器人判斷。
///
/// 抽成純函式的理由：honeypot 欄位在 UI 上是 `Offstage`，
/// widget test 無法對它 `enterText`。把判斷邏輯抽出來就能直接測，
/// 而不是寫一個「看起來有測、其實測不到」的假測試。
abstract final class SubmissionGuard {
  /// honeypot 有任何非空白內容即視為機器人。
  /// 回傳 true 時應**靜默假成功**——不要告訴機器人它被擋了。
  static bool isBot(String honeypotValue) => honeypotValue.trim().isNotEmpty;
}
