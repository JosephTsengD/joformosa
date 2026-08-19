// @spec T-076/Scenario-AdminOnlyAccess
// @spec T-076/Scenario-ApproveFlow
// @spec T-076/Scenario-RejectWithReason
// @spec T-076/Scenario-ModerationAudit
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/core/utils/clock.dart';
import 'package:joformosa/core/utils/failure.dart';
import 'package:joformosa/core/utils/result.dart';
import 'package:joformosa/features/crew_discovery/data/fake_crew_repository.dart';
import 'package:joformosa/features/crew_discovery/domain/crew_repository.dart';
import 'package:joformosa/features/crew_discovery/domain/entities.dart';
import 'package:joformosa/features/moderation/data/fake_moderation_repository.dart';
import 'package:joformosa/features/moderation/domain/moderation_repository.dart';

void main() {
  final clock = FakeClock(DateTime(2026, 8, 15, 10));

  late FakeCrewRepository crews;

  const draft = CrewDraft(
    name: '待審核跑團',
    sport: Sport.run,
    city: City.taipei,
    homeBase: '大安森林公園',
    intro: '這是一段夠長的社團介紹文字，用來通過驗證。',
    instagram: '@pending',
    contactName: '小明',
  );

  setUp(() {
    crews = FakeCrewRepository(clock, latency: Duration.zero);
  });

  FakeModerationRepository mod({required bool admin}) =>
      FakeModerationRepository(crews, clock, isAdminUser: admin);

  Future<String> submitOne() async {
    final r = await crews.submitCrew(draft, idempotencyKey: 'k1');
    return (r as Ok<Crew>).value.id;
  }

  group('AdminOnlyAccess', () {
    test('非管理員讀取佇列被拒，且是 AuthFailure 而非空清單', () async {
      final repo = mod(admin: false);
      final r = await repo.pendingQueue();

      // 回傳空清單是最糟的設計：呼叫端會以為「沒有待審核項目」，
      // 而不是「你沒有權限」——兩者的處理方式完全不同。
      expect(r, isA<Err<List<Crew>>>());
      expect((r as Err<List<Crew>>).failure, isA<AuthFailure>());
    });

    test('非管理員無法核准', () async {
      final crewId = await submitOne();
      final r = await mod(admin: false).approve(crewId);

      expect(r, isA<Err<void>>());
      expect((r as Err<void>).failure, isA<AuthFailure>());
    });

    test('非管理員無法拒絕，即使理由填得很完整', () async {
      final crewId = await submitOne();
      final r = await mod(admin: false).reject(crewId: crewId, reason: '內容不符合規範');

      expect(r, isA<Err<void>>());
      expect((r as Err<void>).failure, isA<AuthFailure>());
    });

    test('非管理員無法讀取稽核紀錄', () async {
      final r = await mod(admin: false).auditLog();
      expect(r, isA<Err<List<ModerationEntry>>>());
    });

    test('isAdmin 對非管理員回傳 false 而非失敗', () async {
      // 這個查詢本身不該是特權操作，否則前端連「要不要顯示入口」都判斷不了
      final r = await mod(admin: false).isAdmin();
      expect(r, isA<Ok<bool>>());
      expect((r as Ok<bool>).value, isFalse);
    });
  });

  group('ApproveFlow', () {
    test('核准後離開待審佇列', () async {
      final crewId = await submitOne();
      final repo = mod(admin: true);

      final before = await repo.pendingQueue();
      expect((before as Ok<List<Crew>>).value, hasLength(1));

      expect(await repo.approve(crewId), isA<Ok<void>>());

      final after = await repo.pendingQueue();
      expect((after as Ok<List<Crew>>).value, isEmpty);
    });

    test('核准會寫入稽核紀錄', () async {
      final crewId = await submitOne();
      final repo = mod(admin: true);
      await repo.approve(crewId);

      final log = (await repo.auditLog() as Ok<List<ModerationEntry>>).value;
      expect(log, hasLength(1));
      expect(log.single.action, ModerationAction.approve);
      expect(log.single.crewId, crewId);
      expect(log.single.at, clock.now());
    });
  });

  group('RejectWithReason', () {
    test('理由為空時被拒絕，且是 ValidationFailure', () async {
      final crewId = await submitOne();
      final repo = mod(admin: true);

      final r = await repo.reject(crewId: crewId, reason: '');
      expect(r, isA<Err<void>>());
      expect((r as Err<void>).failure, isA<ValidationFailure>());
    });

    test('只有空白的理由同樣被拒絕', () async {
      final crewId = await submitOne();
      final r = await mod(admin: true).reject(crewId: crewId, reason: '    ');

      // UI 擋掉空字串是體驗，這一層擋掉才是邊界
      expect(r, isA<Err<void>>());
    });

    test('理由被保存在稽核紀錄中', () async {
      final crewId = await submitOne();
      final repo = mod(admin: true);
      await repo.reject(crewId: crewId, reason: '社團資訊不完整，缺少固定團練時間');

      final log = (await repo.auditLog() as Ok<List<ModerationEntry>>).value;
      expect(log.single.action, ModerationAction.reject);
      expect(log.single.reason, '社團資訊不完整，缺少固定團練時間');
    });

    test('被拒絕後同樣離開佇列', () async {
      final crewId = await submitOne();
      final repo = mod(admin: true);
      await repo.reject(crewId: crewId, reason: '不符規範');

      final after = await repo.pendingQueue();
      expect((after as Ok<List<Crew>>).value, isEmpty);
    });
  });

  group('ModerationAudit', () {
    test('稽核紀錄最新在最前', () async {
      final crewId = await submitOne();
      final repo = mod(admin: true);

      await repo.approve(crewId);
      clock.advance(const Duration(minutes: 5));
      await repo.reject(crewId: crewId, reason: '事後撤下');

      final log = (await repo.auditLog() as Ok<List<ModerationEntry>>).value;
      expect(log, hasLength(2));
      expect(log.first.action, ModerationAction.reject);
      expect(log.first.at.isAfter(log.last.at), isTrue);
    });

    test('可依社團篩選稽核紀錄', () async {
      final crewId = await submitOne();
      final repo = mod(admin: true);
      await repo.approve(crewId);

      final mine =
          (await repo.auditLog(crewId: crewId) as Ok<List<ModerationEntry>>).value;
      final other =
          (await repo.auditLog(crewId: 'not-exist') as Ok<List<ModerationEntry>>).value;

      expect(mine, hasLength(1));
      expect(other, isEmpty);
    });

    test('每一筆都能還原「誰、何時、什麼動作」', () async {
      final crewId = await submitOne();
      final repo = mod(admin: true);
      await repo.reject(crewId: crewId, reason: '廣告內容');

      final e = (await repo.auditLog() as Ok<List<ModerationEntry>>).value.single;
      expect(e.actorId, isNotEmpty);
      expect(e.at, isNotNull);
      expect(e.action, ModerationAction.reject);
      expect(e.reason, isNotNull);
      expect(e.id, isNotEmpty);
    });
  });
}
