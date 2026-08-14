// @spec T-042/Scenario-SessionStatus
import 'package:flutter_test/flutter_test.dart';
import 'package:joincrew/features/crew_discovery/domain/entities.dart';

/// 8.3 邊界案例矩陣中「時間」類別的可執行版本。
/// 注意全程使用固定時間，**沒有任何 DateTime.now()**。
void main() {
  Session sessionAt(DateTime start, {DateTime? end}) => Session(
        id: 's1',
        crewId: 'c1',
        title: 'Test',
        kind: SessionKind.regular,
        startsAt: start,
        endsAt: end,
        locationName: 'Park',
      );

  group('SessionStatus 推導', () {
    final start = DateTime(2026, 8, 22, 19, 30);
    final s = sessionAt(start, end: DateTime(2026, 8, 22, 21));

    test('48 小時前是 scheduled', () {
      expect(s.statusAt(DateTime(2026, 8, 20, 19)), SessionStatus.scheduled);
    });

    test('12 小時前是 imminent', () {
      expect(s.statusAt(DateTime(2026, 8, 22, 7, 30)), SessionStatus.imminent);
    });

    test('開始瞬間即為 ongoing', () {
      expect(s.statusAt(start), SessionStatus.ongoing);
    });

    test('結束瞬間即為 past', () {
      expect(s.statusAt(DateTime(2026, 8, 22, 21)), SessionStatus.past);
    });

    test('沒有 endsAt 時預設 +2 小時', () {
      final noEnd = sessionAt(start);
      expect(noEnd.statusAt(DateTime(2026, 8, 22, 21, 29)), SessionStatus.ongoing);
      expect(noEnd.statusAt(DateTime(2026, 8, 22, 21, 31)), SessionStatus.past);
    });
  });

  group('跨午夜活動（8.3 邊界案例）', () {
    // 22:00 開始、隔日 01:30 結束
    final s = sessionAt(
      DateTime(2026, 8, 22, 22),
      end: DateTime(2026, 8, 23, 1, 30),
    );

    test('隔日 01:00 仍為 ongoing，不可被判定為已結束', () {
      expect(s.statusAt(DateTime(2026, 8, 23, 1)), SessionStatus.ongoing);
      expect(s.isUpcomingAt(DateTime(2026, 8, 23, 1)), isTrue);
    });

    test('隔日 02:00 才進入 past', () {
      expect(s.statusAt(DateTime(2026, 8, 23, 2)), SessionStatus.past);
    });
  });

  group('CrewDetail 分類', () {
    test('upcoming 升冪、past 降冪，且不重不漏', () {
      final now = DateTime(2026, 8, 12, 12);
      final detail = CrewDetail(
        crew: Crew(
          id: 'c1',
          slug: 'c1',
          name: 'C',
          sport: Sport.run,
          city: City.taipei,
          homeBase: 'x',
          activityScore: 1,
          createdAt: DateTime(2026, 1, 1),
        ),
        sessions: <Session>[
          sessionAt(DateTime(2026, 8, 20, 19)),
          sessionAt(DateTime(2026, 8, 5, 19)),
          sessionAt(DateTime(2026, 8, 14, 19)),
          sessionAt(DateTime(2026, 8, 1, 19)),
        ],
      );
      final up = detail.upcoming(now);
      final past = detail.past(now);

      expect(up.length + past.length, 4, reason: '不重不漏');
      expect(up.map((Session s) => s.startsAt.day), <int>[14, 20]);
      expect(past.map((Session s) => s.startsAt.day), <int>[5, 1]);
    });
  });
}
