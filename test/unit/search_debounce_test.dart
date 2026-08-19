// @spec T-070/Scenario-SearchDebounce
// @spec T-070/Scenario-SearchEmptyState
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/core/utils/clock.dart';
import 'package:joformosa/core/utils/result.dart';
import 'package:joformosa/features/crew_discovery/data/fake_crew_repository.dart';
import 'package:joformosa/features/crew_discovery/domain/crew_repository.dart';
import 'package:joformosa/features/crew_discovery/domain/entities.dart';
import 'package:joformosa/features/crew_discovery/presentation/crew_list_controller.dart';
import 'package:joformosa/features/crew_discovery/presentation/crew_list_state.dart';

/// 記錄每一次查詢的 repository，用來數實際發出的請求次數。
class _CountingRepository implements CrewRepository {
  _CountingRepository(this._inner);
  final FakeCrewRepository _inner;

  final List<String> queries = <String>[];

  @override
  Stream<Result<CrewPage>> watchCrews(CrewFilter f, {Cursor? after}) {
    queries.add(f.query);
    return _inner.watchCrews(f, after: after);
  }

  @override
  Future<Result<CrewDetail>> getBySlug(String slug) => _inner.getBySlug(slug);
  @override
  Future<Result<List<Crew>>> getByIds(List<String> ids) => _inner.getByIds(ids);
  @override
  Future<Result<Crew>> submitCrew(CrewDraft d, {required String idempotencyKey}) =>
      _inner.submitCrew(d, idempotencyKey: idempotencyKey);
  @override
  Future<Result<Session>> createSession(SessionDraft d,
          {required String idempotencyKey}) =>
      _inner.createSession(d, idempotencyKey: idempotencyKey);
  @override
  Future<Result<void>> deleteSession(String id) => _inner.deleteSession(id);
  @override
  Future<Result<Crew?>> myCrew(String ownerId) => _inner.myCrew(ownerId);
}

void main() {
  final clock = FakeClock(DateTime(2026, 8, 12, 10));

  late _CountingRepository repo;
  late CrewListController controller;

  setUp(() {
    repo = _CountingRepository(
      FakeCrewRepository(clock, latency: Duration.zero),
    );
    controller = CrewListController(repo);
  });

  tearDown(() => controller.dispose());

  // debounce 是 300ms，用 400ms 當安全邊界
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 400));

  test('連續輸入只發出一次查詢', () async {
    await settle();
    repo.queries.clear();

    // 模擬逐字輸入「大安森林」
    for (final String q in <String>['大', '大安', '大安森', '大安森林']) {
      controller.applyFilter(CrewFilter(query: q));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await settle();

    expect(repo.queries, hasLength(1), reason: '四次輸入應該只觸發一次查詢，實際：${repo.queries}');
    expect(repo.queries.single, '大安森林', reason: '送出的必須是最後一次輸入');
  });

  test('間隔超過 debounce 時間則各自送出', () async {
    await settle();
    repo.queries.clear();

    controller.applyFilter(const CrewFilter(query: '夜跑'));
    await settle();
    controller.applyFilter(const CrewFilter(query: '河濱'));
    await settle();

    expect(repo.queries, <String>['夜跑', '河濱']);
  });

  test('搜尋落空時狀態為 Empty 並保留關鍵字，供空狀態顯示', () async {
    await settle();

    controller.applyFilter(const CrewFilter(query: '這個關鍵字絕對不存在'));
    await settle();

    final state = controller.state;
    expect(state, isA<CrewListEmpty>());
    // 關鍵字必須被帶進狀態，否則畫面只能顯示通用文案，
    // 使用者會以為是網站壞了而不是關鍵字沒中
    expect((state as CrewListEmpty).appliedFilter.query, '這個關鍵字絕對不存在');
  });

  test('清除搜尋後回到有結果的狀態', () async {
    await settle();
    controller.applyFilter(const CrewFilter(query: '不存在'));
    await settle();
    expect(controller.state, isA<CrewListEmpty>());

    controller.applyFilter(const CrewFilter());
    await settle();
    expect(controller.state, isA<CrewListData>());
  });

  test('搜尋命中既有社團', () async {
    await settle();
    controller.applyFilter(const CrewFilter(query: '晨光'));
    await settle();

    final state = controller.state;
    expect(state, isA<CrewListData>());
    expect((state as CrewListData).crews, isNotEmpty);
    expect(state.crews.first.name, contains('晨光'));
  });
}
