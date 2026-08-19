// @spec T-042/Scenario-Degradation
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/core/utils/clock.dart';
import 'package:joformosa/core/utils/failure.dart';
import 'package:joformosa/core/utils/result.dart';
import 'package:joformosa/features/crew_discovery/data/fake_crew_repository.dart';
import 'package:joformosa/features/crew_discovery/data/resilient_crew_repository.dart';
import 'package:joformosa/features/crew_discovery/domain/crew_repository.dart';
import 'package:joformosa/features/crew_discovery/domain/entities.dart';

/// 永遠以指定失敗回應的 repository，用來模擬後端各種故障。
class _AlwaysFailing implements CrewRepository {
  _AlwaysFailing(this.failure);
  final AppFailure failure;
  int submitCalls = 0;

  @override
  Stream<Result<CrewPage>> watchCrews(CrewFilter f, {Cursor? after}) async* {
    yield Err<CrewPage>(failure);
  }

  @override
  Future<Result<CrewDetail>> getBySlug(String slug) async => Err<CrewDetail>(failure);

  @override
  Future<Result<List<Crew>>> getByIds(List<String> ids) async => Err<List<Crew>>(failure);

  @override
  Future<Result<Crew>> submitCrew(CrewDraft d, {required String idempotencyKey}) async {
    submitCalls++;
    return Err<Crew>(failure);
  }

  @override
  Future<Result<Session>> createSession(SessionDraft d,
          {required String idempotencyKey}) async =>
      Err<Session>(failure);

  @override
  Future<Result<void>> deleteSession(String id) async => Err<void>(failure);

  @override
  Future<Result<Crew?>> myCrew(String ownerId) async => Err<Crew?>(failure);
}

void main() {
  final clock = FakeClock(DateTime(2026, 8, 12, 10));
  FakeCrewRepository fake() => FakeCrewRepository(clock, latency: Duration.zero);

  const draft = CrewDraft(
    name: '測試跑團',
    sport: Sport.run,
    city: City.taipei,
    homeBase: '大安森林公園',
    intro: '這是一段夠長的社團介紹文字。',
    instagram: '@t',
    contactName: '小明',
  );

  test('後端斷線時讀取降級到本地資料，畫面不會空白', () async {
    final repo = ResilientCrewRepository(
      primary: _AlwaysFailing(const NetworkFailure()),
      fallback: fake(),
    );

    final page = await repo.watchCrews(const CrewFilter()).last;
    expect(page, isA<Ok<CrewPage>>());
    expect((page as Ok<CrewPage>).value.items, isNotEmpty);
  });

  test('降級旗標會被設定，UI 才能顯示提示', () async {
    final flags = <bool>[];
    final repo = ResilientCrewRepository(
      primary: _AlwaysFailing(const TimeoutFailure()),
      fallback: fake(),
      onDegraded: ({required bool degraded}) => flags.add(degraded),
    );

    await repo.watchCrews(const CrewFilter()).last;
    expect(repo.isDegraded, isTrue);
    expect(flags, contains(true));
  });

  test('找不到資料不觸發降級——那是正常業務結果，不是故障', () async {
    final repo = ResilientCrewRepository(
      primary: _AlwaysFailing(const NotFoundFailure('crew')),
      fallback: fake(),
    );

    final r = await repo.getBySlug('no-such-crew');
    expect(r, isA<Err<CrewDetail>>());
    expect(repo.isDegraded, isFalse, reason: '用假資料掩蓋 404 只會讓真正的問題更難發現');
  });

  test('被 RLS 擋下不觸發降級', () async {
    final repo = ResilientCrewRepository(
      primary: _AlwaysFailing(const AuthFailure()),
      fallback: fake(),
    );

    final r = await repo.getByIds(<String>['crew-0']);
    expect(r, isA<Err<List<Crew>>>());
    expect(repo.isDegraded, isFalse);
  });

  test('寫入永不降級——假裝送出成功是最糟的謊', () async {
    final primary = _AlwaysFailing(const NetworkFailure());
    final fallback = fake();
    final repo = ResilientCrewRepository(primary: primary, fallback: fallback);

    final r = await repo.submitCrew(draft, idempotencyKey: 'k1');

    expect(r, isA<Err<Crew>>(), reason: '寫入失敗必須誠實回報');
    expect(primary.submitCalls, 1);
    // 確認沒有偷偷寫進 fallback
    final mine = await fallback.myCrew('me');
    expect((mine as Ok<Crew?>).value, isNull);
  });
}
