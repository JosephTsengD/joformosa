// @spec T-090/Scenario-WeekendBoundary
// @spec T-090/Scenario-TodayBoundary
// @spec T-090/Scenario-FilterByWindow
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/core/utils/clock.dart';
import 'package:joformosa/core/utils/result.dart';
import 'package:joformosa/features/crew_discovery/data/fake_crew_repository.dart';
import 'package:joformosa/features/crew_discovery/domain/entities.dart';

void main() {
  // 2026-08-17 是星期一，方便推算整週
  DateTime monday(int hour) => DateTime(2026, 8, 17, hour);
  DateTime dayOfWeek(int weekday, int hour) => DateTime(2026, 8, 16 + weekday, hour);

  group('TodayBoundary', () {
    test('今天的區間是當日 00:00 到隔日 00:00', () {
      final range = TimeWindow.today.rangeFor(monday(14))!;
      expect(range.start, DateTime(2026, 8, 17));
      expect(range.end, DateTime(2026, 8, 18));
    });

    test('深夜 23:59 仍屬於當天，不會跳到隔天', () {
      final range = TimeWindow.today.rangeFor(DateTime(2026, 8, 17, 23, 59))!;
      expect(range.start, DateTime(2026, 8, 17));
    });

    test('區間是半開的：隔日 00:00 不屬於今天', () {
      final range = TimeWindow.today.rangeFor(monday(10))!;
      expect(range.contains(DateTime(2026, 8, 17, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2026, 8, 18)), isFalse,
          reason: '半開區間，否則「今天」與「明天」會重疊一個瞬間');
    });

    test('不限時間回傳 null，代表不加任何條件', () {
      expect(TimeWindow.any.rangeFor(monday(10)), isNull);
    });
  });

  group('WeekendBoundary', () {
    test('平日查詢週末，指向接下來的週六到週一', () {
      // 週一查 → 週六 8/22 00:00 至 週一 8/24 00:00
      final range = TimeWindow.weekend.rangeFor(monday(10))!;
      expect(range.start, DateTime(2026, 8, 22));
      expect(range.end, DateTime(2026, 8, 24));
      expect(range.start.weekday, DateTime.saturday);
    });

    test('週五查詢，指向隔天開始的週末', () {
      final range = TimeWindow.weekend.rangeFor(dayOfWeek(DateTime.friday, 20))!;
      expect(range.start.weekday, DateTime.saturday);
      expect(range.start, DateTime(2026, 8, 22));
    });

    test('週六當天查詢，指向「現在這個」週末而非下一個', () {
      // 這是最容易寫錯的一條：站在週六卻被導到下週六，
      // 使用者會覺得「今天明明有團，為什麼篩不到」
      final range = TimeWindow.weekend.rangeFor(dayOfWeek(DateTime.saturday, 9))!;
      expect(range.start, DateTime(2026, 8, 22), reason: '應為今天，不是下週六');
      expect(range.end, DateTime(2026, 8, 24));
    });

    test('週日當天查詢，區間只剩今天一天', () {
      final range = TimeWindow.weekend.rangeFor(dayOfWeek(DateTime.sunday, 9))!;
      expect(range.start, DateTime(2026, 8, 23));
      expect(range.end, DateTime(2026, 8, 24));
    });

    test('週日晚上的活動仍在週末區間內', () {
      final range = TimeWindow.weekend.rangeFor(monday(10))!;
      expect(range.contains(DateTime(2026, 8, 23, 22)), isTrue);
      expect(range.contains(DateTime(2026, 8, 24, 0, 1)), isFalse, reason: '週一凌晨不算週末');
    });
  });

  group('本週', () {
    test('本週是從今天起算七天，不是到週日為止', () {
      // 刻意選擇「未來七天」而非曆法週：
      // 週日查詢時，曆法週只剩幾小時，對使用者毫無用處
      final range = TimeWindow.thisWeek.rangeFor(dayOfWeek(DateTime.sunday, 10))!;
      expect(range.end.difference(range.start).inDays, 7);
    });
  });

  group('FilterByWindow', () {
    test('週末篩選只留下週末有場次的社團', () async {
      final clock = FakeClock(monday(10));
      final repo = FakeCrewRepository(clock, latency: Duration.zero);

      final all = await repo.watchCrews(const CrewFilter()).first;
      final weekend =
          await repo.watchCrews(const CrewFilter(timeWindow: TimeWindow.weekend)).first;

      final allItems = (all as Ok<CrewPage>).value.items;
      final weekendItems = (weekend as Ok<CrewPage>).value.items;

      expect(weekendItems.length, lessThanOrEqualTo(allItems.length));
      // 每一個結果都必須真的有週末場次，而不只是 nextSession 剛好在週末
      final range = TimeWindow.weekend.rangeFor(clock.now())!;
      for (final Crew c in weekendItems) {
        final detail = await repo.getBySlug(c.slug);
        final sessions = (detail as Ok<CrewDetail>).value.sessions;
        expect(
          sessions.any((Session s) => range.contains(s.startsAt)),
          isTrue,
          reason: '${c.name} 在週末沒有任何場次卻被留下',
        );
      }
    });

    test('時間區間會進入網址並可還原', () {
      const filter = CrewFilter(timeWindow: TimeWindow.weekend);
      final restored = CrewFilter.fromQueryParams(
        Uri.parse(filter.toLocation()).queryParameters,
      );
      expect(restored.timeWindow, TimeWindow.weekend);
    });

    test('不限時間不會產生多餘的網址參數', () {
      expect(const CrewFilter().toQueryParams().containsKey('when'), isFalse);
    });

    test('時間區間計入 activeCount', () {
      expect(const CrewFilter(timeWindow: TimeWindow.today).activeCount, 1);
      expect(const CrewFilter().activeCount, 0);
    });
  });
}
