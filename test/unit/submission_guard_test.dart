// @spec T-060/Scenario-Honeypot
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/features/crew_admin/presentation/submission_guard.dart';

void main() {
  test('honeypot 有值視為機器人', () {
    expect(SubmissionGuard.isBot('anything'), isTrue);
    expect(SubmissionGuard.isBot('  x  '), isTrue);
  });

  test('honeypot 空白或全空格視為真人', () {
    expect(SubmissionGuard.isBot(''), isFalse);
    expect(SubmissionGuard.isBot('   '), isFalse);
  });
}
