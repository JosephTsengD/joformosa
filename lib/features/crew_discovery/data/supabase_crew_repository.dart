// 一律用前綴 import 第三方 SDK。
// supabase_flutter 會轉出 gotrue 的 Session、User 等型別，
// 與本專案 domain 的 Session 直接撞名（Error: 'Session' is imported from both...）。
// 前綴讓衝突不可能發生，也讓讀者一眼看出哪些型別來自外部。
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/utils/clock.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/result.dart';
import '../domain/crew_repository.dart';
import '../domain/entities.dart';

/// 真實後端：共用一份可寫的 Postgres。
///
/// 與 FakeCrewRepository 共用同一組 domain 契約——這是 Repository
/// 抽象層不是裝飾品的證明。
///
/// **授權完全不在這一層。** 這裡送出的每個請求都會經過 RLS，
/// 即使有人拿 anon key 直連 PostgREST 也拿不到不該拿的東西。
/// 見 supabase/migrations/0002_rls.sql 與 docs/PRODUCTION.md 的滲透測試。
class SupabaseCrewRepository implements CrewRepository {
  SupabaseCrewRepository(this._db, this._clock);

  final sb.SupabaseClient _db;
  final Clock _clock;

  static const _pageSize = 8;

  @override
  Stream<Result<CrewPage>> watchCrews(CrewFilter f, {Cursor? after}) async* {
    try {
      // 用 RPC 而非 client 端迴圈：LATERAL JOIN 一次取回「下一場」。
      // 在 client 端跑迴圈的話，20 張卡片就是 21 次網路往返。
      final rows = await _db.rpc<dynamic>(
        'crews_with_next_session',
        params: <String, dynamic>{
          'p_city': f.city?.code,
          'p_sport': f.sport?.name,
          'p_tags':
              f.styles.isEmpty ? null : f.styles.map((StyleTag s) => s.code).toList(),
          'p_query': f.query.isEmpty ? null : f.query,
          'p_limit': _pageSize,
          'p_after_score': after?.afterScore,
          'p_after_id': after?.afterId,
        },
      );

      final items = <Crew>[];
      final list = rows is List<dynamic> ? rows : const <dynamic>[];
      for (final dynamic row in list) {
        // 單筆格式錯誤只丟棄該筆。一列壞資料不該讓整頁變成錯誤畫面。
        final parsed = _tryCrew(row);
        if (parsed != null) items.add(parsed);
      }

      yield Ok<CrewPage>(
        CrewPage(
          items: items,
          nextCursor: items.length < _pageSize
              ? null
              : Cursor(
                  afterScore: items.last.activityScore,
                  afterId: items.last.id,
                ),
        ),
      );
    } on sb.PostgrestException catch (e) {
      yield Err<CrewPage>(_mapPostgrest(e));
    } on Object catch (e) {
      yield Err<CrewPage>(_mapUnknown(e));
    }
  }

  @override
  Future<Result<CrewDetail>> getBySlug(String slug) async {
    try {
      final row = await _db
          .from('crews')
          .select(
            '*, crew_style_tags(tag_code), outbound_links(platform,url), '
            'sessions(id,crew_id,title,kind,starts_at,ends_at,location_name)',
          )
          .eq('slug', slug)
          .maybeSingle();

      if (row == null) return const Err<CrewDetail>(NotFoundFailure('crew'));

      final crew = _tryCrew(row);
      if (crew == null) return const Err<CrewDetail>(NotFoundFailure('crew'));

      final sessions = <Session>[];
      final raw = row['sessions'];
      final list = raw is List<dynamic> ? raw : const <dynamic>[];
      for (final dynamic s in list) {
        final parsed = _trySession(s);
        if (parsed != null) sessions.add(parsed);
      }

      return Ok<CrewDetail>(CrewDetail(crew: crew, sessions: sessions));
    } on sb.PostgrestException catch (e) {
      return Err<CrewDetail>(_mapPostgrest(e));
    } on Object catch (e) {
      return Err<CrewDetail>(_mapUnknown(e));
    }
  }

  @override
  Future<Result<List<Crew>>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const Ok<List<Crew>>(<Crew>[]);
    try {
      final rows = await _db
          .from('crews')
          .select('*, crew_style_tags(tag_code), outbound_links(platform,url)')
          .inFilter('id', ids);

      final out = <Crew>[];
      for (final dynamic r in rows) {
        final parsed = _tryCrew(r);
        if (parsed != null) out.add(parsed);
      }
      return Ok<List<Crew>>(out);
    } on sb.PostgrestException catch (e) {
      return Err<List<Crew>>(_mapPostgrest(e));
    } on Object catch (e) {
      return Err<List<Crew>>(_mapUnknown(e));
    }
  }

  @override
  Future<Result<Crew>> submitCrew(
    CrewDraft d, {
    required String idempotencyKey,
  }) async {
    try {
      // submit_crew() 在伺服器端以 unique(idempotency_key) 保證重試不產生兩筆，
      // 並一律寫入 status='pending'——送出不等於發布。
      final row = await _db.rpc<dynamic>(
        'submit_crew',
        params: <String, dynamic>{
          'p_payload': <String, dynamic>{
            'name': d.name,
            'sport': d.sport.name,
            'city_code': d.city.code,
            'home_base': d.homeBase,
            'intro': d.intro,
            'instagram': d.instagram,
            'contact_name': d.contactName,
            'regular_schedule': d.regularSchedule,
            'styles': d.styles.map((StyleTag s) => s.code).toList(),
          },
          'p_idempotency_key': idempotencyKey,
        },
      );

      final crew = _tryCrew(row);
      if (crew == null) {
        return const Err<Crew>(UnknownFailure('submit_crew returned no row'));
      }
      return Ok<Crew>(crew);
    } on sb.PostgrestException catch (e) {
      return Err<Crew>(_mapPostgrest(e));
    } on Object catch (e) {
      return Err<Crew>(_mapUnknown(e));
    }
  }

  @override
  Future<Result<Session>> createSession(
    SessionDraft d, {
    required String idempotencyKey,
  }) async {
    try {
      final row = await _db
          .from('sessions')
          .insert(<String, dynamic>{
            'crew_id': d.crewId,
            'title': d.title,
            'kind': d.kind.name,
            // 一律以 UTC 送出，伺服器存 timestamptz，讀回來再轉本地
            'starts_at': d.startsAt.toUtc().toIso8601String(),
            'ends_at': d.endsAt?.toUtc().toIso8601String(),
            'location_name': d.locationName,
          })
          .select()
          .single();

      final session = _trySession(row);
      if (session == null) {
        return const Err<Session>(UnknownFailure('insert returned no row'));
      }
      return Ok<Session>(session);
    } on sb.PostgrestException catch (e) {
      return Err<Session>(_mapPostgrest(e));
    } on Object catch (e) {
      return Err<Session>(_mapUnknown(e));
    }
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    try {
      await _db.from('sessions').delete().eq('id', sessionId);
      return const Ok<void>(null);
    } on sb.PostgrestException catch (e) {
      return Err<void>(_mapPostgrest(e));
    } on Object catch (e) {
      return Err<void>(_mapUnknown(e));
    }
  }

  @override
  Future<Result<Crew?>> myCrew(String ownerId) async {
    try {
      // 不需要（也不應該）在前端再過濾一次 owner——
      // RLS 已保證使用者只看得到自己的未發布社團。
      // 前端重複過濾等於多一個可能寫錯的信任邊界。
      final row = await _db
          .from('crews')
          .select('*, crew_style_tags(tag_code), outbound_links(platform,url)')
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) return const Ok<Crew?>(null);
      return Ok<Crew?>(_tryCrew(row));
    } on sb.PostgrestException catch (e) {
      return Err<Crew?>(_mapPostgrest(e));
    } on Object catch (e) {
      return Err<Crew?>(_mapUnknown(e));
    }
  }

  /// 保留給未來的「本地時間 vs 伺服器時間」校正
  DateTime get now => _clock.now();

  // ── 例外轉譯 ────────────────────────────────────────────
  // data 層的職責：把所有原始例外轉成 AppFailure。
  // domain 與 presentation 永遠不會看到 PostgrestException。

  AppFailure _mapPostgrest(sb.PostgrestException e) {
    switch (e.code) {
      case 'PGRST116':
        return const NotFoundFailure('row');
      case '42501': // insufficient_privilege：被 RLS 擋下
        return const AuthFailure(reason: 'RLS denied');
      case '23505': // unique_violation
        return const ValidationFailure(<String, String>{'_': 'duplicate'});
      case '23514': // check_violation，例如 ends_at <= starts_at
        return const ValidationFailure(<String, String>{'_': 'constraint'});
      case 'P0001': // raise exception，例如 rate_limited
        if (e.message.contains('rate')) {
          return const RateLimitFailure(Duration(minutes: 1));
        }
        return ValidationFailure(<String, String>{'_': e.message});
      default:
        return UnknownFailure(e.message);
    }
  }

  AppFailure _mapUnknown(Object e) {
    final text = e.toString().toLowerCase();
    // Supabase 免費方案暫停、DNS 失敗、離線都會落在這裡。
    // 這些是可重試的，要跟「資料格式錯誤」區分開來。
    if (text.contains('socket') ||
        text.contains('failed host lookup') ||
        text.contains('connection') ||
        text.contains('clientexception') ||
        text.contains('xmlhttprequest')) {
      return const NetworkFailure();
    }
    if (text.contains('timeout')) return const TimeoutFailure();
    return UnknownFailure(e.toString());
  }

  // ── 反序列化 ────────────────────────────────────────────
  // 回傳 nullable 而非拋例外：一列壞資料只丟那一列。

  Crew? _tryCrew(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      String? instagram;
      final links = raw['outbound_links'];
      if (links is List<dynamic>) {
        for (final dynamic l in links) {
          if (l is Map<String, dynamic> && l['platform'] == 'instagram') {
            instagram = l['url'] as String?;
          }
        }
      }

      final tags = <StyleTag>[];
      final rawTags = raw['crew_style_tags'];
      if (rawTags is List<dynamic>) {
        for (final dynamic t in rawTags) {
          if (t is Map<String, dynamic>) {
            tags.add(StyleTag.byCode(t['tag_code'] as String));
          }
        }
      }

      return Crew(
        id: raw['id'] as String,
        slug: raw['slug'] as String,
        name: raw['name'] as String,
        handle: raw['handle'] as String?,
        sport: Sport.values.byName(raw['sport'] as String),
        city: City.byCode(raw['city_code'] as String),
        homeBase: raw['home_base'] as String,
        intro: raw['intro'] as String?,
        regularSchedule: raw['regular_schedule'] as String?,
        activityScore: (raw['activity_score'] as num?)?.toInt() ?? 0,
        styles: tags,
        nextSession: _trySession(raw['next_session']),
        instagramUrl: instagram,
        ownerId: raw['owner_id'] as String?,
        createdAt: DateTime.parse(raw['created_at'] as String).toLocal(),
      );
    } on Object {
      return null;
    }
  }

  Session? _trySession(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      return Session(
        id: raw['id'] as String,
        crewId: raw['crew_id'] as String,
        title: raw['title'] as String,
        kind: SessionKind.values.byName(raw['kind'] as String),
        // 伺服器回 UTC，一律轉本地呈現。
        // 業務判斷（是否已結束）仍以 Session.statusAt 推導，見 ADR-006。
        startsAt: DateTime.parse(raw['starts_at'] as String).toLocal(),
        endsAt: raw['ends_at'] == null
            ? null
            : DateTime.parse(raw['ends_at'] as String).toLocal(),
        locationName: raw['location_name'] as String,
        note: raw['note'] as String?,
      );
    } on Object {
      return null;
    }
  }
}
