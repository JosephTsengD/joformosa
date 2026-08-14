import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities.dart';

/// 示範模式的本地寫入儲存。
///
/// 為什麼不用「伺服器端每晚重置」？
/// ─────────────────────────────────────────────────────────
/// 共用一份可寫的資料庫，代表兩個訪客會互相看到對方的測試資料。
/// 面試官 A 送出「測試跑團 123」，面試官 B 打開就看到它——很難看。
///
/// 改成寫在瀏覽器本地之後，每個訪客都有自己的沙盒：
/// · 送出的社團、新增的活動重新整理後仍在
/// · 不同訪客完全隔離
/// · 使用者可以隨時按「重置示範資料」回到初始狀態
/// · 零後端成本
///
/// 代價是換裝置不同步——但示範模式本來就不需要同步。
class LocalDraftStore {
  LocalDraftStore(this._prefs);

  final SharedPreferences _prefs;

  static const _crewsKey = 'demo.crews.v1';
  static const _sessionsKey = 'demo.sessions.v1';

  /// 同步讀取。SharedPreferences 實例在 main() 已經 await 取得，
  /// 這裡讀的是記憶體中的快取，所以可以同步——
  /// repository 的建構子因此不需要是非同步的。
  List<Crew> loadCrews() {
    final raw = _prefs.getString(_crewsKey);
    if (raw == null || raw.isEmpty) return const <Crew>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((dynamic e) => _crewFromJson(e as Map<String, dynamic>)).toList();
    } on Object {
      // 格式不符（例如改版後的舊資料）就丟棄，不要讓使用者卡在壞掉的畫面
      return const <Crew>[];
    }
  }

  Map<String, List<Session>> loadSessions() {
    final raw = _prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return <String, List<Session>>{};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (String k, dynamic v) => MapEntry<String, List<Session>>(
          k,
          (v as List<dynamic>)
              .map((dynamic e) => _sessionFromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
    } on Object {
      return <String, List<Session>>{};
    }
  }

  Future<void> saveCrews(List<Crew> crews) async {
    await _prefs.setString(
      _crewsKey,
      jsonEncode(crews.map(_crewToJson).toList()),
    );
  }

  Future<void> saveSessions(Map<String, List<Session>> sessions) async {
    await _prefs.setString(
      _sessionsKey,
      jsonEncode(
        sessions.map(
          (String k, List<Session> v) => MapEntry<String, List<dynamic>>(
            k,
            v.map(_sessionToJson).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_crewsKey);
    await _prefs.remove(_sessionsKey);
  }

  bool get hasData => (_prefs.getString(_crewsKey) ?? '').isNotEmpty;

  // ── 序列化 ──────────────────────────────────────────────
  // 刻意寫在 data 層而非 domain：domain 不該知道自己會被存成 JSON。
  // 這也是不用 code generation 的代價之一，但換來 clone 即可執行。

  static Map<String, dynamic> _crewToJson(Crew c) => <String, dynamic>{
        'id': c.id,
        'slug': c.slug,
        'name': c.name,
        'handle': c.handle,
        'sport': c.sport.name,
        'city': c.city.code,
        'homeBase': c.homeBase,
        'intro': c.intro,
        'regularSchedule': c.regularSchedule,
        'activityScore': c.activityScore,
        'styles': c.styles.map((StyleTag t) => t.code).toList(),
        'instagramUrl': c.instagramUrl,
        'ownerId': c.ownerId,
        'createdAt': c.createdAt.toIso8601String(),
      };

  static Crew _crewFromJson(Map<String, dynamic> m) => Crew(
        id: m['id'] as String,
        slug: m['slug'] as String,
        name: m['name'] as String,
        handle: m['handle'] as String?,
        sport: Sport.values.byName(m['sport'] as String),
        city: City.byCode(m['city'] as String),
        homeBase: m['homeBase'] as String,
        intro: m['intro'] as String?,
        regularSchedule: m['regularSchedule'] as String?,
        activityScore: m['activityScore'] as int,
        styles: ((m['styles'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => StyleTag.byCode(e as String))
            .toList(),
        instagramUrl: m['instagramUrl'] as String?,
        ownerId: m['ownerId'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );

  static Map<String, dynamic> _sessionToJson(Session s) => <String, dynamic>{
        'id': s.id,
        'crewId': s.crewId,
        'title': s.title,
        'kind': s.kind.name,
        'startsAt': s.startsAt.toIso8601String(),
        'endsAt': s.endsAt?.toIso8601String(),
        'locationName': s.locationName,
        'note': s.note,
      };

  static Session _sessionFromJson(Map<String, dynamic> m) => Session(
        id: m['id'] as String,
        crewId: m['crewId'] as String,
        title: m['title'] as String,
        kind: SessionKind.values.byName(m['kind'] as String),
        startsAt: DateTime.parse(m['startsAt'] as String),
        endsAt: m['endsAt'] == null ? null : DateTime.parse(m['endsAt'] as String),
        locationName: m['locationName'] as String,
        note: m['note'] as String?,
      );
}
