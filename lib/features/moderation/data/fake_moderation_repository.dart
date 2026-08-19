import '../../../core/utils/clock.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/id_gen.dart';
import '../../../core/utils/result.dart';
import '../../crew_discovery/data/fake_crew_repository.dart';
import '../../crew_discovery/domain/entities.dart';
import '../domain/moderation_repository.dart';

/// 開發／示範用的審核實作。
///
/// 它同時是權限規則的可執行規格：SupabaseModerationRepository 必須
/// 在相同輸入下產生相同的失敗型別。
class FakeModerationRepository implements ModerationRepository {
  FakeModerationRepository(this._crews, this._clock, {bool isAdminUser = false})
      : _isAdmin = isAdminUser;

  final FakeCrewRepository _crews;
  final Clock _clock;
  final IdGen _ids = IdGen();

  bool _isAdmin;
  final List<ModerationEntry> _log = <ModerationEntry>[];
  final Set<String> _approved = <String>{};
  final Set<String> _rejected = <String>{};

  /// 僅供開發選單切換身分用
  void setAdmin({required bool value}) => _isAdmin = value;

  @override
  Future<Result<bool>> isAdmin() async => Ok<bool>(_isAdmin);

  @override
  Future<Result<List<Crew>>> pendingQueue() async {
    if (!_isAdmin) {
      return const Err<List<Crew>>(AuthFailure(reason: 'admin_required'));
    }

    final mine = await _crews.myCrew('me');
    final crew = mine.valueOrNull;
    final pending = <Crew>[
      if (crew != null && !_approved.contains(crew.id) && !_rejected.contains(crew.id))
        crew,
    ];
    return Ok<List<Crew>>(pending);
  }

  @override
  Future<Result<void>> approve(String crewId) async {
    if (!_isAdmin) {
      return const Err<void>(AuthFailure(reason: 'admin_required'));
    }
    _approved.add(crewId);
    _record(crewId, ModerationAction.approve, null);
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> reject({
    required String crewId,
    required String reason,
  }) async {
    if (!_isAdmin) {
      return const Err<void>(AuthFailure(reason: 'admin_required'));
    }
    if (reason.trim().isEmpty) {
      return const Err<void>(
        ValidationFailure(<String, String>{'reason': 'required'}),
      );
    }
    _rejected.add(crewId);
    _record(crewId, ModerationAction.reject, reason.trim());
    return const Ok<void>(null);
  }

  @override
  Future<Result<List<ModerationEntry>>> auditLog({String? crewId}) async {
    if (!_isAdmin) {
      return const Err<List<ModerationEntry>>(
        AuthFailure(reason: 'admin_required'),
      );
    }
    final entries = crewId == null
        ? _log
        : _log.where((ModerationEntry e) => e.crewId == crewId).toList();
    // 最新在最前
    return Ok<List<ModerationEntry>>(
      <ModerationEntry>[...entries]..sort(
          (ModerationEntry a, ModerationEntry b) => b.at.compareTo(a.at),
        ),
    );
  }

  void _record(String crewId, ModerationAction action, String? reason) {
    _log.add(
      ModerationEntry(
        id: _ids.next('mod'),
        crewId: crewId,
        crewName: crewId,
        action: action,
        actorId: 'admin',
        at: _clock.now(),
        reason: reason,
      ),
    );
  }
}
