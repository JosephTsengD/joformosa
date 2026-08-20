// @spec T-074/Scenario-CalendarUtc
// @spec T-074/Scenario-IcsFormat
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/core/utils/calendar_link.dart';
import 'package:joformosa/features/crew_discovery/domain/entities.dart';

void main() {
  Session session({DateTime? start, DateTime? end, String title = 'Social Run'}) =>
      Session(
        id: 'sess-1',
        crewId: 'crew-1',
        title: title,
        kind: SessionKind.regular,
        startsAt: start ?? DateTime(2026, 8, 22, 7, 30),
        endsAt: end,
        locationName: '大安森林公園南側門',
      );

  group('CalendarUtc', () {
    test('時間一律轉成 UTC 並帶 Z 結尾', () {
      // 不加 Z 的話 Google 會用「使用者行事曆的時區」解讀，
      // 台灣的 07:30 在別人那裡會變成別的時間
      final formatted = CalendarLink.formatUtc(DateTime.utc(2026, 8, 22, 7, 30));
      expect(formatted, '20260822T073000Z');
      expect(formatted.endsWith('Z'), isTrue);
    });

    test('個位數的月日時分補零', () {
      final formatted = CalendarLink.formatUtc(DateTime.utc(2026, 1, 5, 9, 8, 7));
      expect(formatted, '20260105T090807Z');
    });

    test('沒有結束時間時預設為開始後兩小時', () {
      final url = CalendarLink.googleCalendarUrl(
        session: session(start: DateTime.utc(2026, 8, 22, 7, 30)),
        crewName: '晨光跑者',
      );
      final dates = Uri.parse(url).queryParameters['dates']!;
      expect(dates, '20260822T073000Z/20260822T093000Z');
    });

    test('網址包含社團名稱與地點', () {
      final url = CalendarLink.googleCalendarUrl(
        session: session(),
        crewName: '晨光跑者',
      );
      final params = Uri.parse(url).queryParameters;

      expect(params['action'], 'TEMPLATE');
      expect(params['text'], contains('晨光跑者'));
      expect(params['location'], '大安森林公園南側門');
    });

    test('中文與特殊字元正確編碼，網址可解析', () {
      final url = CalendarLink.googleCalendarUrl(
        session: session(title: '間歇課表 400m × 8, 休息 90 秒'),
        crewName: '配速實驗室',
      );
      expect(() => Uri.parse(url), returnsNormally);
      expect(
        Uri.parse(url).queryParameters['text'],
        contains('400m × 8, 休息 90 秒'),
      );
    });
  });

  group('IcsFormat', () {
    final ics = CalendarLink.buildIcs(
      session: session(end: DateTime(2026, 8, 22, 9)),
      crewName: '晨光跑者',
      now: DateTime.utc(2026, 8, 19, 3),
    );

    test('使用 CRLF 換行（RFC 5545 要求）', () {
      // 只用 \n 的話部分行事曆軟體會整份拒絕，
      // 而且錯誤訊息通常只說「格式無效」
      expect(ics.contains('\r\n'), isTrue);
      expect(RegExp(r'(?<!\r)\n').hasMatch(ics), isFalse, reason: '不應出現沒有 \\r 的裸 \\n');
    });

    test('結構完整', () {
      expect(ics, startsWith('BEGIN:VCALENDAR'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('END:VEVENT'));
      expect(ics.trimRight(), endsWith('END:VCALENDAR'));
      expect(ics, contains('UID:sess-1@joformosa'));
    });

    test('逗號與分號被跳脫', () {
      final escaped = CalendarLink.escape('地點：A, B; C');
      expect(escaped, r'地點：A\, B\; C');
    });

    test('反斜線先跳脫，避免二次跳脫', () {
      // 順序寫反的話，'\,' 會先變成 '\\,' 再變成 '\\\\,'
      expect(CalendarLink.escape(r'a\b'), r'a\\b');
      expect(CalendarLink.escape('a\nb'), r'a\nb');
    });
  });
}
