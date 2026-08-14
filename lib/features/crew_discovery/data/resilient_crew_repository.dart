import 'dart:async';

import '../../../core/utils/failure.dart';
import '../../../core/utils/result.dart';
import '../domain/crew_repository.dart';
import '../domain/entities.dart';

/// 降級層：主要走真實後端，後端不可用時退回本地合成資料（唯讀）。
///
/// 為什麼需要這個
/// ─────────────────────────────────────────────────────────
/// Supabase 免費方案在 7 天無活動後會暫停專案。沒有降級的話，
/// 訪客（例如面試官）會看到一片空白，而且不知道是網站壞了還是自己網路壞了。
///
/// 有降級的話，最壞情況是「看到示範資料且明確被告知」——
/// 這比白畫面好非常多。
///
/// **降級只套用在讀取。** 寫入失敗必須誠實回報失敗，
/// 絕不能假裝成功——使用者以為社團送出了，其實什麼都沒發生，
/// 那比直接報錯糟糕得多。
class ResilientCrewRepository implements CrewRepository {
  ResilientCrewRepository({
    required CrewRepository primary,
    required CrewRepository fallback,
    this.onDegraded,
  })  : _primary = primary,
        _fallback = fallback;

  final CrewRepository _primary;
  final CrewRepository _fallback;

  /// 進入或離開降級狀態時通知 UI（用來顯示提示條）
  final void Function({required bool degraded})? onDegraded;

  bool _degraded = false;
  bool get isDegraded => _degraded;

  void _setDegraded({required bool value}) {
    if (_degraded == value) return;
    _degraded = value;
    onDegraded?.call(degraded: value);
  }

  /// 只有「後端連不上」才降級。
  /// 找不到資料、驗證失敗、被 RLS 擋下都是正常的業務結果，不該降級——
  /// 那些情況降級只會用假資料掩蓋真正的問題。
  static bool _shouldFallback(AppFailure f) => f is NetworkFailure || f is TimeoutFailure;

  @override
  Stream<Result<CrewPage>> watchCrews(CrewFilter filter, {Cursor? after}) async* {
    await for (final Result<CrewPage> result
        in _primary.watchCrews(filter, after: after)) {
      switch (result) {
        case Ok<CrewPage>():
          _setDegraded(value: false);
          yield result;
        case Err<CrewPage>(:final failure):
          if (!_shouldFallback(failure)) {
            yield result;
            continue;
          }
          _setDegraded(value: true);
          yield* _fallback.watchCrews(filter, after: after);
      }
    }
  }

  @override
  Future<Result<CrewDetail>> getBySlug(String slug) async {
    final result = await _primary.getBySlug(slug);
    return switch (result) {
      Ok<CrewDetail>() => _okAnd(result),
      Err<CrewDetail>(:final failure) =>
        _shouldFallback(failure) ? _degradeTo(await _fallback.getBySlug(slug)) : result,
    };
  }

  @override
  Future<Result<List<Crew>>> getByIds(List<String> ids) async {
    final result = await _primary.getByIds(ids);
    return switch (result) {
      Ok<List<Crew>>() => _okAnd(result),
      Err<List<Crew>>(:final failure) =>
        _shouldFallback(failure) ? _degradeTo(await _fallback.getByIds(ids)) : result,
    };
  }

  // ── 寫入一律不降級 ──────────────────────────────────────
  // 假裝寫入成功是最糟的一種謊。

  @override
  Future<Result<Crew>> submitCrew(
    CrewDraft draft, {
    required String idempotencyKey,
  }) =>
      _primary.submitCrew(draft, idempotencyKey: idempotencyKey);

  @override
  Future<Result<Session>> createSession(
    SessionDraft draft, {
    required String idempotencyKey,
  }) =>
      _primary.createSession(draft, idempotencyKey: idempotencyKey);

  @override
  Future<Result<void>> deleteSession(String sessionId) =>
      _primary.deleteSession(sessionId);

  @override
  Future<Result<Crew?>> myCrew(String ownerId) => _primary.myCrew(ownerId);

  Result<T> _okAnd<T>(Result<T> result) {
    _setDegraded(value: false);
    return result;
  }

  Result<T> _degradeTo<T>(Result<T> result) {
    _setDegraded(value: true);
    return result;
  }
}
