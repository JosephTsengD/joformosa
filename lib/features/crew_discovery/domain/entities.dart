enum Sport { run, ride, hyrox, other }

enum SessionKind { regular, special, race, social }

/// 活動狀態**不存在資料庫**，完全由時間推導。
/// 理由（ADR-006）：存欄位就需要排程去翻轉它，而排程一定會遲到、會漏、
/// 會在時區邊界出錯，導致「已結束的活動還顯示即將到來」。推導式狀態永遠正確。
enum SessionStatus { scheduled, imminent, ongoing, past }

class City {
  const City(this.code, this.zh, this.en);
  final String code;
  final String zh;
  final String en;

  static const taipei = City('TPE', '台北', 'Taipei');
  static const newTaipei = City('TPH', '新北', 'New Taipei');
  static const taoyuan = City('TYN', '桃園', 'Taoyuan');
  static const hsinchu = City('HSZ', '新竹', 'Hsinchu');
  static const taichung = City('TXG', '台中', 'Taichung');
  static const tainan = City('TNN', '台南', 'Tainan');
  static const kaohsiung = City('KHH', '高雄', 'Kaohsiung');
  static const yilan = City('ILA', '宜蘭', 'Yilan');

  static const all = <City>[
    taipei,
    newTaipei,
    taoyuan,
    hsinchu,
    taichung,
    tainan,
    kaohsiung,
    yilan,
  ];

  static City byCode(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => taipei);

  @override
  bool operator ==(Object other) => other is City && other.code == code;
  @override
  int get hashCode => code.hashCode;
}

class StyleTag {
  const StyleTag(this.code, this.zh, this.en);
  final String code;
  final String zh;
  final String en;

  static const beginner = StyleTag('beginner', '新手友善', 'Beginner friendly');
  static const night = StyleTag('night', '夜間', 'Night');
  static const trail = StyleTag('trail', '越野/山徑', 'Trail');
  static const social = StyleTag('social', '歡樂社交', 'Social');
  static const longRun = StyleTag('long', '長距離', 'Long distance');
  static const interval = StyleTag('interval', '間歇/速度', 'Intervals');
  static const morning = StyleTag('morning', '晨跑', 'Morning');
  static const riverside = StyleTag('riverside', '河濱', 'Riverside');
  static const racePrep = StyleTag('race_prep', '備賽衝刺', 'Race prep');
  static const office = StyleTag('office', '上班族', 'Office workers');

  static const all = <StyleTag>[
    beginner,
    night,
    trail,
    social,
    longRun,
    interval,
    morning,
    riverside,
    racePrep,
    office,
  ];

  static StyleTag byCode(String code) =>
      all.firstWhere((t) => t.code == code, orElse: () => beginner);

  @override
  bool operator ==(Object other) => other is StyleTag && other.code == code;
  @override
  int get hashCode => code.hashCode;
}

class Session {
  const Session({
    required this.id,
    required this.crewId,
    required this.title,
    required this.kind,
    required this.startsAt,
    required this.locationName,
    this.endsAt,
    this.note,
  });

  final String id;
  final String crewId;
  final String title;
  final SessionKind kind;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String locationName;
  final String? note;

  /// 沒有 endsAt 時預設 +2h（F-05 邊界案例）
  DateTime get effectiveEnd => endsAt ?? startsAt.add(const Duration(hours: 2));

  /// 純函式，100% 可單元測試。測試時注入 FakeClock。
  SessionStatus statusAt(DateTime now) {
    if (now.isBefore(startsAt.subtract(const Duration(hours: 24)))) {
      return SessionStatus.scheduled;
    }
    if (now.isBefore(startsAt)) return SessionStatus.imminent;
    if (now.isBefore(effectiveEnd)) return SessionStatus.ongoing;
    return SessionStatus.past;
  }

  bool isUpcomingAt(DateTime now) => statusAt(now) != SessionStatus.past;
}

class Crew {
  const Crew({
    required this.id,
    required this.slug,
    required this.name,
    required this.sport,
    required this.city,
    required this.homeBase,
    required this.activityScore,
    required this.createdAt,
    this.handle,
    this.intro,
    this.regularSchedule,
    this.styles = const <StyleTag>[],
    this.nextSession,
    this.instagramUrl,
    this.ownerId,
  });

  final String id;
  final String slug;
  final String name;
  final String? handle;
  final Sport sport;
  final City city;
  final String homeBase;
  final String? intro;
  final String? regularSchedule;
  final int activityScore;
  final List<StyleTag> styles;
  final Session? nextSession;
  final String? instagramUrl;
  final String? ownerId;
  final DateTime createdAt;

  /// 「NEW」徽章是**衍生**的，不存布林值（會腐爛）。
  bool isNewAt(DateTime now) => now.difference(createdAt).inDays < 30;

  Crew copyWith({int? activityScore, Session? nextSession, String? ownerId}) => Crew(
        id: id,
        slug: slug,
        name: name,
        handle: handle,
        sport: sport,
        city: city,
        homeBase: homeBase,
        intro: intro,
        regularSchedule: regularSchedule,
        activityScore: activityScore ?? this.activityScore,
        styles: styles,
        nextSession: nextSession ?? this.nextSession,
        instagramUrl: instagramUrl,
        ownerId: ownerId ?? this.ownerId,
        createdAt: createdAt,
      );
}

class CrewDetail {
  const CrewDetail({required this.crew, required this.sessions});
  final Crew crew;
  final List<Session> sessions;

  List<Session> upcoming(DateTime now) =>
      sessions.where((s) => s.isUpcomingAt(now)).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  List<Session> past(DateTime now) => sessions.where((s) => !s.isUpcomingAt(now)).toList()
    ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
}

enum CrewSort { score, nextSession }

class CrewFilter {
  const CrewFilter({
    this.sport,
    this.city,
    this.styles = const <StyleTag>{},
    this.query = '',
    this.sort = CrewSort.score,
  });

  final Sport? sport;
  final City? city;
  final Set<StyleTag> styles;
  final String query;
  final CrewSort sort;

  int get activeCount =>
      (sport != null ? 1 : 0) +
      (city != null ? 1 : 0) +
      styles.length +
      (query.isEmpty ? 0 : 1);

  bool get isEmpty => activeCount == 0;

  CrewFilter copyWith({
    Sport? sport,
    City? city,
    Set<StyleTag>? styles,
    String? query,
    CrewSort? sort,
    bool clearSport = false,
    bool clearCity = false,
  }) =>
      CrewFilter(
        sport: clearSport ? null : (sport ?? this.sport),
        city: clearCity ? null : (city ?? this.city),
        styles: styles ?? this.styles,
        query: query ?? this.query,
        sort: sort ?? this.sort,
      );

  /// 篩選狀態 ↔ URL query string 雙向綁定，讓搜尋結果可分享（Web）
  Map<String, String> toQueryParams() => <String, String>{
        if (sport != null) 'sport': sport!.name,
        if (city != null) 'city': city!.code,
        if (styles.isNotEmpty) 'styles': styles.map((s) => s.code).join(','),
        if (query.isNotEmpty) 'q': query,
        if (sort != CrewSort.score) 'sort': sort.name,
      };

  static CrewFilter fromQueryParams(Map<String, String> p) {
    final rawStyles = p['styles'];
    return CrewFilter(
      sport: p['sport'] == null
          ? null
          : Sport.values.where((s) => s.name == p['sport']).firstOrNull,
      city: p['city'] == null ? null : City.byCode(p['city']!),
      styles: rawStyles == null || rawStyles.isEmpty
          ? const <StyleTag>{}
          : rawStyles.split(',').map(StyleTag.byCode).toSet(),
      query: p['q'] ?? '',
      sort: p['sort'] == 'nextSession' ? CrewSort.nextSession : CrewSort.score,
    );
  }
}

/// keyset 分頁游標（不用 offset：資料變動時會漏或重複）
class Cursor {
  const Cursor({required this.afterScore, required this.afterId});
  final int afterScore;
  final String afterId;
}

class CrewPage {
  const CrewPage({required this.items, required this.nextCursor});
  final List<Crew> items;
  final Cursor? nextCursor;
  bool get hasMore => nextCursor != null;
}
