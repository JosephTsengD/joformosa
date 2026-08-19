// @spec T-042/Scenario-RelativeTime
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/core/l10n/strings.dart';
import 'package:joformosa/core/utils/formatters.dart';

void main() {
  const tf = TimeFormatter(Strings('zh-Hant'));

  test('今天晚上顯示「今晚」', () {
    final now = DateTime(2026, 8, 12, 9);
    expect(tf.relative(DateTime(2026, 8, 12, 19, 30), now), contains('今晚'));
  });

  test('今天白天顯示「今天」', () {
    final now = DateTime(2026, 8, 12, 6);
    expect(tf.relative(DateTime(2026, 8, 12, 8), now), contains('今天'));
  });

  /// 這是 `difference().inDays` 會答錯的經典案例：
  /// 23:00 到隔日 01:00 只差 2 小時，但**不是同一天**。
  test('跨日界線 2 小時仍算「明天」而非「今天」', () {
    final now = DateTime(2026, 8, 12, 23);
    final target = DateTime(2026, 8, 13, 1);
    expect(tf.relative(target, now), contains('明天'));
  });

  test('7 天以上顯示絕對日期', () {
    final now = DateTime(2026, 8, 12, 9);
    final out = tf.relative(DateTime(2026, 8, 25, 7, 30), now);
    expect(out, contains('8/25'));
    expect(out, contains('07:30'));
  });
}
