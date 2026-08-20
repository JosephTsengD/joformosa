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

/// 時間區間篩選。
///
/// 為什麼沒有「夜間」這個選項？
/// ─────────────────────────────────────────────────────────
/// 夜間不是連續區間——它是每天的 17:00–24:00，散落在整個時間軸上。
/// 一旦允許非連續區間，後端查詢就沒辦法用單純的 `between`，
/// 而且時區換算會變成一場災難。
///
/// 「夜間」本來就已經是風格標籤（StyleTag.night），用那個就好。
/// **選項該長什麼樣，要由資料結構決定，不是由介面美感決定。**
enum TimeWindow { any, today, thisWeek, weekend }

/// 半開區間 [start, end)
class DateRange {
  const DateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
}

extension TimeWindowRange on TimeWindow {
  /// 把語意轉成具體的時間區間。
  ///
  /// **在客戶端算完再送出去**，後端只收到 from / to 兩個時間戳。
  /// 這樣「今天」是誰的今天、週末從哪天開始，只需要在一個地方定義，
  /// 而且那個地方是可以寫測試的純函式。
  /// 讓 SQL 去理解「週末」的語意，等於把時區問題散佈到兩個系統。
  DateRange? rangeFor(DateTime now) {
    final startOfDay = DateTime(now.year, now.month, now.day);
    switch (this) {
      case TimeWindow.any:
        return null;
      case TimeWindow.today:
        return DateRange(startOfDay, startOfDay.add(const Duration(days: 1)));
      case TimeWindow.thisWeek:
        return DateRange(startOfDay, startOfDay.add(const Duration(days: 7)));
      case TimeWindow.weekend:
        // 已經在週末就用當下這個，否則抓下一個週六
        final isWeekend = now.weekday >= DateTime.saturday;
        final daysToSaturday = isWeekend ? 0 : DateTime.saturday - now.weekday;
        final saturday = startOfDay.add(Duration(days: daysToSaturday));
        // 週末結束 = 週一 00:00。已經是週日時只剩一天。
        final end = isWeekend
            ? startOfDay.add(
                Duration(days: DateTime.sunday - now.weekday + 1),
              )
            : saturday.add(const Duration(days: 2));
        return DateRange(isWeekend ? startOfDay : saturday, end);
    }
  }
}

enum CrewSort { score, nextSession }

class CrewFilter {
  const CrewFilter({
    this.sport,
    this.city,
    this.styles = const <StyleTag>{},
    this.query = '',
    this.sort = CrewSort.score,
    this.timeWindow = TimeWindow.any,
  });

  final Sport? sport;
  final City? city;
  final Set<StyleTag> styles;
  final String query;
  final CrewSort sort;
  final TimeWindow timeWindow;

  int get activeCount =>
      (sport != null ? 1 : 0) +
      (city != null ? 1 : 0) +
      styles.length +
      (query.isEmpty ? 0 : 1) +
      (timeWindow == TimeWindow.any ? 0 : 1);

  bool get isEmpty => activeCount == 0;

  CrewFilter copyWith({
    Sport? sport,
    City? city,
    Set<StyleTag>? styles,
    String? query,
    CrewSort? sort,
    TimeWindow? timeWindow,
    bool clearSport = false,
    bool clearCity = false,
  }) =>
      CrewFilter(
        sport: clearSport ? null : (sport ?? this.sport),
        city: clearCity ? null : (city ?? this.city),
        styles: styles ?? this.styles,
        query: query ?? this.query,
        sort: sort ?? this.sort,
        timeWindow: timeWindow ?? this.timeWindow,
      );

  /// 篩選狀態 ↔ URL query string 雙向綁定，讓搜尋結果可分享（Web）
  Map<String, String> toQueryParams() => <String, String>{
        if (sport != null) 'sport': sport!.name,
        if (city != null) 'city': city!.code,
        if (styles.isNotEmpty) 'styles': styles.map((s) => s.code).join(','),
        if (query.isNotEmpty) 'q': query,
        if (sort != CrewSort.score) 'sort': sort.name,
        if (timeWindow != TimeWindow.any) 'when': timeWindow.name,
      };

  /// 轉成可分享的網址路徑。
  ///
  /// 放在 domain 而非 router：這是 CrewFilter 自己的行為，
  /// 而且純字串運算，不需要任何 Flutter 依賴，可以單獨測試。
  String toLocation() {
    final params = toQueryParams();
    if (params.isEmpty) return '/';
    return Uri(path: '/', queryParameters: params).toString();
  }

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
      timeWindow:
          TimeWindow.values.where((TimeWindow w) => w.name == p['when']).firstOrNull ??
              TimeWindow.any,
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
