import 'dart:math';

/// 隨機 ID 產生器。
///
/// 為什麼不用 `DateTime.now().microsecondsSinceEpoch` 當 ID？
/// 1. 它是 `DateTime.now()` 的變形，會讓「禁止直接讀系統時間」的規則出現漏洞。
/// 2. 時間戳在快速連續呼叫時可能碰撞。
/// 3. 測試中無法重現（注入 seed 就可以）。
class IdGen {
  IdGen([Random? random]) : _random = random ?? Random.secure();

  final Random _random;
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  String next([String prefix = '']) {
    final body = List<String>.generate(
      16,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join();
    return prefix.isEmpty ? body : '$prefix-$body';
  }
}
