import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/result.dart';
import '../../crew_discovery/domain/crew_repository.dart';
import '../../crew_discovery/domain/entities.dart';

sealed class AdminState {
  const AdminState();
}

final class AdminLoading extends AdminState {
  const AdminLoading();
}

final class AdminNoCrew extends AdminState {
  const AdminNoCrew();
}

final class AdminHasCrew extends AdminState {
  const AdminHasCrew(this.crew, this.detail);
  final Crew crew;
  final CrewDetail? detail;
}

final class AdminError extends AdminState {
  const AdminError(this.failure);
  final AppFailure failure;
}

class AdminController extends StateNotifier<AdminState> {
  AdminController(this._repo, this._ownerId) : super(const AdminLoading()) {
    load();
  }

  final CrewRepository _repo;
  final String _ownerId;

  Future<void> load() async {
    state = const AdminLoading();
    final result = await _repo.myCrew(_ownerId);
    switch (result) {
      case Ok<Crew?>(:final value):
        if (value == null) {
          state = const AdminNoCrew();
        } else {
          final detail = await _repo.getBySlug(value.slug);
          state = AdminHasCrew(value, detail.valueOrNull);
        }
      case Err<Crew?>(:final failure):
        state = AdminError(failure);
    }
  }

  Future<Result<Crew>> submitCrew(CrewDraft draft, String idempotencyKey) async {
    final r = await _repo.submitCrew(draft, idempotencyKey: idempotencyKey);
    if (r.isOk) await load();
    return r;
  }

  Future<Result<Session>> createSession(SessionDraft draft, String idempotencyKey) async {
    final r = await _repo.createSession(draft, idempotencyKey: idempotencyKey);
    if (r.isOk) await load();
    return r;
  }
}

final adminProvider = StateNotifierProvider<AdminController, AdminState>(
  (Ref ref) => AdminController(
    ref.watch(crewRepositoryProvider),
    ref.watch(currentUserProvider)?.id ?? 'me',
  ),
);
