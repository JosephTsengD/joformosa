import 'dart:async';

import '../../../core/utils/clock.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/id_gen.dart';
import '../../../core/utils/result.dart';
import '../domain/crew_repository.dart';
import '../domain/entities.dart';
import 'local_draft_store.dart';
import 'seed_data.dart';

/// 記憶體實作：讓 `flutter run` 立刻可用，不需先架 Supabase。
///
/// 它同時是 **domain 契約的可執行規格**——SupabaseCrewRepository 必須
/// 通過同一組 repository contract test（test/unit/crew_repository_contract.dart）。
class FakeCrewRepository implements CrewRepository {
  FakeCrewRepository(
    this._clock, {
    this.latency = const Duration(milliseconds: 420),
    LocalDraftStore? store,
  })  : _seed = SeedData(_clock.now()),
        _store = store {
    // 還原使用者上次送出的資料。同步讀取，因為 SharedPreferences 實例
    // 在 main() 已 await 取得，這裡讀的是記憶體快取。
    final s = store;
    if (s != null) {
      _submitted.addAll(s.loadCrews());
      _extraSessions.addAll(s.loadSessions());
    }
  }

  final Clock _clock;
  final Duration latency;
  final SeedData _seed;
  final LocalDraftStore? _store;

  static const pageSize = 8;

  /// 由 DevMenu 切換，用來手動驗證錯誤與空狀態（F-01 / F-02）
  bool simulateFailure = false;
  bool simulateEmpty = false;

  final List<Crew> _submitted = <Crew>[];
  final Map<String, List<Session>> _extraSessions = <String, List<Session>>{};
  final Set<String> _usedIdempotencyKeys = <String>{};
  final IdGen _ids = IdGen();

  List<Crew> get _all => <Crew>[..._seed.crews, ..._submitted];

  List<Session> _sessionsOf(String crewId) => <Session>[
        ...?_seed.sessionsByCrew[crewId],
        ...?_extraSessions[crewId],
      ];

  Crew _withNext(Crew c) {
    final now = _clock.now();
    final upcoming = _sessionsOf(c.id).where((s) => s.isUpcomingAt(now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return c.copyWith(nextSession: upcoming.isEmpty ? null : upcoming.first);
  }

  bool _matches(Crew c, CrewFilter f) {
    if (f.sport != null && c.sport != f.sport) return false;
    if (f.city != null && c.city != f.city) return false;
    // 時間區間看的是「有沒有任何一場落在區間內」，
    // 不是只看 nextSession——某團可能今天沒場次但週末有兩場。
    final range = f.timeWindow.rangeFor(_clock.now());
    if (range != null &&
        !_sessionsOf(c.id).any((Session s) => range.contains(s.startsAt))) {
      return false;
    }
    if (f.styles.isNotEmpty && !f.styles.every(c.styles.contains)) return false;
    if (f.query.isNotEmpty) {
      final q = f.query.toLowerCase();
      final hay = '${c.name} ${c.handle ?? ''} ${c.intro ?? ''}'.toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }

  @override
  Stream<Result<CrewPage>> watchCrews(CrewFilter filter, {Cursor? after}) async* {
    await Future<void>.delayed(latency);
    if (simulateFailure) {
      yield const Err<CrewPage>(NetworkFailure());
      return;
    }

    var list = _all.where((c) => _matches(c, filter)).map(_withNext).toList();

    if (simulateEmpty) list = <Crew>[];

    switch (filter.sort) {
      case CrewSort.score:
        list.sort((a, b) {
          final byScore = b.activityScore.compareTo(a.activityScore);
          return byScore != 0 ? byScore : a.id.compareTo(b.id);
        });
      case CrewSort.nextSession:
        list.sort((a, b) {
          final an = a.nextSession?.startsAt;
          final bn = b.nextSession?.startsAt;
          if (an == null && bn == null) return a.id.compareTo(b.id);
          if (an == null) return 1; // 無場次的排最後
          if (bn == null) return -1;
          return an.compareTo(bn);
        });
    }

    // keyset 分頁：以 (score, id) 為游標，避免 offset 在資料變動時漏/重
    var start = 0;
    if (after != null) {
      final idx = list.indexWhere((c) => c.id == after.afterId);
      start = idx < 0 ? 0 : idx + 1;
    }
    final slice = list.skip(start).take(pageSize).toList();
    final hasMore = start + slice.length < list.length;

    yield Ok<CrewPage>(
      CrewPage(
        items: slice,
        nextCursor: hasMore && slice.isNotEmpty
            ? Cursor(afterScore: slice.last.activityScore, afterId: slice.last.id)
            : null,
      ),
    );
  }

  @override
  Future<Result<CrewDetail>> getBySlug(String slug) async {
    await Future<void>.delayed(latency);
    if (simulateFailure) return const Err<CrewDetail>(NetworkFailure());
    final crew = _all.where((c) => c.slug == slug).firstOrNull;
    if (crew == null) return const Err<CrewDetail>(NotFoundFailure('crew'));
    return Ok<CrewDetail>(
      CrewDetail(crew: _withNext(crew), sessions: _sessionsOf(crew.id)),
    );
  }

  @override
  Future<Result<List<Crew>>> getByIds(List<String> ids) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return Ok<List<Crew>>(
      _all.where((c) => ids.contains(c.id)).map(_withNext).toList(),
    );
  }

  @override
  Future<Result<Crew>> submitCrew(CrewDraft d, {required String idempotencyKey}) async {
    await Future<void>.delayed(latency);
    // F-10：帶 idempotency_key，網路重試不產生兩筆
    if (_usedIdempotencyKeys.contains(idempotencyKey)) {
      final existing = _submitted.lastOrNull;
      if (existing != null) return Ok<Crew>(existing);
    }
    _usedIdempotencyKeys.add(idempotencyKey);

    final now = _clock.now();
    final crew = Crew(
      id: 'crew-own-${_submitted.length}',
      slug: 'my-crew-${_submitted.length}',
      name: d.name,
      handle: d.name.toUpperCase(),
      sport: d.sport,
      city: d.city,
      homeBase: d.homeBase,
      intro: d.intro,
      regularSchedule: d.regularSchedule,
      activityScore: 0,
      styles: d.styles.toList(),
      instagramUrl: 'https://www.instagram.com/${d.instagram.replaceAll('@', '')}/',
      ownerId: 'me',
      createdAt: now,
    );
    _submitted.add(crew);
    await _persist();
    return Ok<Crew>(crew);
  }

  @override
  Future<Result<Session>> createSession(SessionDraft d,
      {required String idempotencyKey}) async {
    await Future<void>.delayed(latency);
    if (_usedIdempotencyKeys.contains(idempotencyKey)) {
      final existing = _extraSessions[d.crewId]?.lastOrNull;
      if (existing != null) return Ok<Session>(existing);
    }
    _usedIdempotencyKeys.add(idempotencyKey);

    final s = Session(
      id: _ids.next('sess'),
      crewId: d.crewId,
      title: d.title,
      kind: d.kind,
      startsAt: d.startsAt,
      endsAt: d.endsAt,
      locationName: d.locationName,
    );
    _extraSessions.putIfAbsent(d.crewId, () => <Session>[]).add(s);

    // 積分：公告活動 +3（與 6.5 節的權重一致）
    final i = _submitted.indexWhere((c) => c.id == d.crewId);
    if (i >= 0) {
      _submitted[i] =
          _submitted[i].copyWith(activityScore: _submitted[i].activityScore + 3);
    }
    await _persist();
    return Ok<Session>(s);
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    for (final entry in _extraSessions.entries) {
      entry.value.removeWhere((s) => s.id == sessionId);
    }
    await _persist();
    return const Ok<void>(null);
  }

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    await store.saveCrews(_submitted);
    await store.saveSessions(_extraSessions);
  }

  /// 清空使用者在示範模式中建立的所有資料，回到初始的合成資料。
  /// 種子資料本身不受影響——那是唯讀的。
  Future<void> resetDemoData() async {
    _submitted.clear();
    _extraSessions.clear();
    _usedIdempotencyKeys.clear();
    await _store?.clear();
  }

  /// 使用者是否曾在示範模式中寫入過資料
  bool get hasUserData => _submitted.isNotEmpty;

  @override
  Future<Result<Crew?>> myCrew(String ownerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final c = _submitted.where((c) => c.ownerId == 'me').lastOrNull;
    return Ok<Crew?>(c == null ? null : _withNext(c));
  }
}
