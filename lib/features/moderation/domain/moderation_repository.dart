import '../../../core/utils/result.dart';
import '../../crew_discovery/domain/entities.dart';

enum ModerationAction { approve, reject }

/// 稽核紀錄。只增不改——這是它作為「稽核」的全部意義。
/// 任何可以被修改的紀錄，在爭議發生時都沒有證據力。
class ModerationEntry {
  const ModerationEntry({
    required this.id,
    required this.crewId,
    required this.crewName,
    required this.action,
    required this.actorId,
    required this.at,
    this.reason,
  });

  final String id;
  final String crewId;
  final String crewName;
  final ModerationAction action;
  final String actorId;
  final DateTime at;
  final String? reason;
}

abstract interface class ModerationRepository {
  /// 是否具備管理員身分。
  ///
  /// 這個判斷的**權威來源在伺服器**，前端只是拿來決定要不要畫出入口。
  /// 就算有人偽造這個回傳值強行進入畫面，後面每一個動作仍然會被 RLS 擋下。
  Future<Result<bool>> isAdmin();

  Future<Result<List<Crew>>> pendingQueue();

  Future<Result<void>> approve(String crewId);

  /// 理由為必填。空字串必須被**這一層**拒絕，不能只靠 UI 驗證——
  /// UI 驗證是體驗，不是邊界。
  Future<Result<void>> reject({required String crewId, required String reason});

  Future<Result<List<ModerationEntry>>> auditLog({String? crewId});
}
