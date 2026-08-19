// @spec T-060/Scenario-DemoPersistence
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/core/utils/clock.dart';
import 'package:joformosa/core/utils/result.dart';
import 'package:joformosa/features/crew_discovery/data/fake_crew_repository.dart';
import 'package:joformosa/features/crew_discovery/data/local_draft_store.dart';
import 'package:joformosa/features/crew_discovery/domain/crew_repository.dart';
import 'package:joformosa/features/crew_discovery/domain/entities.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  final clock = FakeClock(DateTime(2026, 8, 12, 10));

  const draft = CrewDraft(
    name: '示範跑團',
    sport: Sport.run,
    city: City.taipei,
    homeBase: '大安森林公園南側門',
    intro: '這是一個用來驗證本地持久化的社團介紹文字。',
    instagram: '@demo',
    contactName: '小明',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  FakeCrewRepository build() => FakeCrewRepository(
        clock,
        latency: Duration.zero,
        store: LocalDraftStore(prefs),
      );

  test('送出的社團在重建 repository 後仍存在（等同重新整理頁面）', () async {
    final first = build();
    final created = await first.submitCrew(draft, idempotencyKey: 'k1');
    expect(created, isA<Ok<Crew>>());

    // 重建 = 使用者重新整理瀏覽器
    final second = build();
    final mine = await second.myCrew('me');

    expect((mine as Ok<Crew?>).value, isNotNull);
    expect(mine.value!.name, '示範跑團');
  });

  test('新增的活動一併被保留', () async {
    final first = build();
    final created = await first.submitCrew(draft, idempotencyKey: 'k1');
    final crewId = (created as Ok<Crew>).value.id;

    await first.createSession(
      SessionDraft(
        crewId: crewId,
        title: '週三團練',
        kind: SessionKind.regular,
        startsAt: DateTime(2026, 8, 20, 19, 30),
        locationName: '田徑場',
      ),
      idempotencyKey: 'k2',
    );

    final second = build();
    final detail = await second.getBySlug((created).value.slug);
    final sessions = (detail as Ok<CrewDetail>).value.sessions;

    expect(sessions.where((Session s) => s.title == '週三團練'), hasLength(1));
  });

  test('重置後回到初始狀態，但種子資料不受影響', () async {
    final repo = build();
    await repo.submitCrew(draft, idempotencyKey: 'k1');
    expect(repo.hasUserData, isTrue);

    await repo.resetDemoData();
    expect(repo.hasUserData, isFalse);

    final mine = await repo.myCrew('me');
    expect((mine as Ok<Crew?>).value, isNull);

    // 種子資料是唯讀的，重置不該動到它
    final page = await repo.watchCrews(const CrewFilter()).first;
    expect((page as Ok<CrewPage>).value.items, isNotEmpty);
  });

  test('儲存內容毀損時安全降級，不讓使用者卡在壞畫面', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'demo.crews.v1': 'this-is-not-json',
    });
    final broken = await SharedPreferences.getInstance();
    final store = LocalDraftStore(broken);

    expect(store.loadCrews(), isEmpty);
    expect(store.loadSessions(), isEmpty);
  });
}
