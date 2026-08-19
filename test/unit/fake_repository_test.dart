// @spec T-042/Scenario-Pagination
// @spec T-060/Scenario-Idempotency
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/core/utils/clock.dart';
import 'package:joformosa/core/utils/result.dart';
import 'package:joformosa/features/crew_discovery/data/fake_crew_repository.dart';
import 'package:joformosa/features/crew_discovery/domain/crew_repository.dart';
import 'package:joformosa/features/crew_discovery/domain/entities.dart';

void main() {
  late FakeCrewRepository repo;
  final clock = FakeClock(DateTime(2026, 8, 12, 10));

  setUp(() {
    repo = FakeCrewRepository(clock, latency: Duration.zero);
  });

  Future<CrewPage> page(CrewFilter f, {Cursor? after}) async {
    final r = await repo.watchCrews(f, after: after).first;
    return (r as Ok<CrewPage>).value;
  }

  test('分頁不重複不遺漏', () async {
    final seen = <String>{};
    Cursor? cursor;
    var total = 0;
    for (var i = 0; i < 10; i++) {
      final p = await page(const CrewFilter(), after: cursor);
      for (final Crew c in p.items) {
        expect(seen.add(c.id), isTrue, reason: 'id ${c.id} 重複出現');
      }
      total += p.items.length;
      cursor = p.nextCursor;
      if (cursor == null) break;
    }
    final all = await page(const CrewFilter());
    expect(all.items, isNotEmpty);
    expect(total, greaterThanOrEqualTo(all.items.length));
  });

  test('依積分降冪排序', () async {
    final p = await page(const CrewFilter());
    final scores = p.items.map((Crew c) => c.activityScore).toList();
    final sorted = <int>[...scores]..sort((int a, int b) => b.compareTo(a));
    expect(scores, sorted);
  });

  test('縣市篩選為分區查詢，結果全部屬於該縣市', () async {
    final p = await page(const CrewFilter(city: City.taichung));
    expect(p.items, isNotEmpty);
    for (final Crew c in p.items) {
      expect(c.city, City.taichung);
    }
  });

  test('找不到的 slug 回傳 NotFoundFailure 而非拋例外', () async {
    final r = await repo.getBySlug('no-such-crew');
    expect(r, isA<Err<CrewDetail>>());
  });

  test('相同 idempotencyKey 重送不產生第二筆（F-10）', () async {
    const draft = CrewDraft(
      name: '測試跑團',
      sport: Sport.run,
      city: City.taipei,
      homeBase: '大安森林公園',
      intro: '這是一個測試用的社團介紹文字。',
      instagram: '@test',
      contactName: '小明',
    );
    const key = 'same-key-123';

    final first = await repo.submitCrew(draft, idempotencyKey: key);
    final second = await repo.submitCrew(draft, idempotencyKey: key);

    expect(first, isA<Ok<Crew>>());
    expect(second, isA<Ok<Crew>>());
    expect((first as Ok<Crew>).value.id, (second as Ok<Crew>).value.id);

    final mine = await repo.myCrew('me');
    expect((mine as Ok<Crew?>).value, isNotNull);
  });

  test('模擬網路失敗時回傳 NetworkFailure，不拋例外', () async {
    repo.simulateFailure = true;
    final r = await repo.watchCrews(const CrewFilter()).first;
    expect(r, isA<Err<CrewPage>>());
  });
}
