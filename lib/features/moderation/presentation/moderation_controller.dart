import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/result.dart';
import '../../crew_discovery/domain/entities.dart';
import '../domain/moderation_repository.dart';

sealed class ModerationState {
  const ModerationState();
}

final class ModerationLoading extends ModerationState {
  const ModerationLoading();
}

/// 非管理員。刻意與「載入失敗」分開建模——
/// 兩者的畫面與後續動作完全不同，混在一起會讓 UI 說謊。
final class ModerationForbidden extends ModerationState {
  const ModerationForbidden();
}

final class ModerationReady extends ModerationState {
  const ModerationReady({required this.pending, required this.log});
  final List<Crew> pending;
  final List<ModerationEntry> log;
}

final class ModerationError extends ModerationState {
  const ModerationError(this.failure);
  final AppFailure failure;
}

class ModerationController extends StateNotifier<ModerationState> {
  ModerationController(this._repo) : super(const ModerationLoading()) {
    load();
  }

  final ModerationRepository _repo;

  Future<void> load() async {
    state = const ModerationLoading();

    final admin = await _repo.isAdmin();
    if (admin.valueOrNull != true) {
      state = const ModerationForbidden();
      return;
    }

    final queue = await _repo.pendingQueue();
    switch (queue) {
      case Err<List<Crew>>(:final failure):
        state = failure is AuthFailure
            ? const ModerationForbidden()
            : ModerationError(failure);
      case Ok<List<Crew>>(:final value):
        final log = await _repo.auditLog();
        state = ModerationReady(
            pending: value, log: log.valueOrNull ?? const <ModerationEntry>[]);
    }
  }

  Future<Result<void>> approve(String crewId) async {
    final r = await _repo.approve(crewId);
    if (r.isOk) await load();
    return r;
  }

  Future<Result<void>> reject(String crewId, String reason) async {
    final r = await _repo.reject(crewId: crewId, reason: reason);
    if (r.isOk) await load();
    return r;
  }
}

final moderationProvider = StateNotifierProvider<ModerationController, ModerationState>(
  (Ref ref) => ModerationController(ref.watch(moderationRepositoryProvider)),
);
