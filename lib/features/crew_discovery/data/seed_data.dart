import 'dart:math';

import '../domain/entities.dart';

/// 合成種子資料（第 6.1 節：**不爬取原站**）。
///
/// 設計重點：
/// 1. 固定 seed → 每次執行結果相同 → golden test 才穩定。
/// 2. 活動時間符合真實分布：平日晚上 19:00–20:00 約 60%，
///    週末早上 06:00–08:00 約 35%。
/// 3. **刻意製造髒資料**測試韌性：無活動的社團、只有過往活動的社團、
///    超長名稱、缺 IG、跨午夜的活動。
class SeedData {
  SeedData(this.now) : _rnd = Random(20260812);

  final DateTime now;
  final Random _rnd;

  late final List<Crew> crews = _buildCrews();
  late final Map<String, List<Session>> sessionsByCrew = _buildSessions();

  static const _names = <List<String>>[
    ['晨光跑者 Dawn Runners', 'DAWN', 'TPE', 'run'],
    ['信義夜跑團', 'XINYI NIGHT', 'TPE', 'run'],
    ['河濱慢慢跑', 'SLOWLY', 'TPE', 'run'],
    ['台北山徑越野俱樂部 Taipei Trail Explorers Club', 'TTEC', 'TPE', 'run'],
    ['Pace Lab 配速實驗室', 'PACELAB', 'TPE', 'run'],
    ['大稻埕自行車隊', 'DDC CYCLING', 'TPE', 'ride'],
    ['HYROX Taipei Box', 'HRX TPE', 'TPE', 'hyrox'],
    ['板橋跑步俱樂部', 'BQ RUN', 'TPH', 'run'],
    ['新北輕鬆跑', 'EASY NTP', 'TPH', 'run'],
    ['淡水海線車隊', 'TAMSUI RIDE', 'TPH', 'ride'],
    ['桃園機捷跑團', 'TYN RUNNERS', 'TYN', 'run'],
    ['青埔晨練社', 'QINGPU AM', 'TYN', 'run'],
    ['新竹科園跑者', 'HSP RUNNERS', 'HSZ', 'run'],
    ['風城自行車', 'WINDCITY', 'HSZ', 'ride'],
    ['台中綠園道跑團', 'TXG GREENWAY', 'TXG', 'run'],
    ['逢甲夜跑', 'FCU NIGHT', 'TXG', 'run'],
    ['中台灣越野社', 'CTW TRAIL', 'TXG', 'run'],
    ['HYROX Taichung', 'HRX TXG', 'TXG', 'hyrox'],
    ['台南古都跑者', 'TAINAN OLD', 'TNN', 'run'],
    ['安平海風跑團', 'ANPING', 'TNN', 'run'],
    ['高雄愛河跑團', 'LOVE RIVER', 'KHH', 'run'],
    ['港都自行車隊', 'HARBOR RIDE', 'KHH', 'ride'],
    ['西子灣晨跑會', 'SIZIWAN AM', 'KHH', 'run'],
    ['宜蘭田野跑團', 'YILAN FIELD', 'ILA', 'run'],
    ['羅東鐵人訓練', 'LUODONG TRI', 'ILA', 'other'],
  ];

  static const _bases = <String>[
    '大安森林公園南側門',
    '河濱公園自行車道起點',
    '市民廣場',
    '田徑場暖身區',
    '捷運站 2 號出口',
    '運動中心大廳',
    '河堤入口',
    '車站前廣場',
  ];

  static const _titles = <String>[
    'Social Run',
    'Dash & Run',
    'LSD 長距離',
    'Track Night',
    '間歇課表',
    'Coffee Run',
    '河濱輕鬆跑',
    'Hill Repeats',
  ];

  List<Crew> _buildCrews() {
    final out = <Crew>[];
    for (var i = 0; i < _names.length; i++) {
      final n = _names[i];
      final sport = switch (n[3]) {
        'ride' => Sport.ride,
        'hyrox' => Sport.hyrox,
        'other' => Sport.other,
        _ => Sport.run,
      };
      final styleCount = 1 + _rnd.nextInt(3);
      final styles = <StyleTag>{};
      while (styles.length < styleCount) {
        styles.add(StyleTag.all[_rnd.nextInt(StyleTag.all.length)]);
      }
      // 髒資料 ①：index 7 沒有 IG 連結
      final hasIg = i != 7;
      out.add(
        Crew(
          id: 'crew-$i',
          slug: _slug(n[1], i),
          name: n[0],
          handle: n[1],
          sport: sport,
          city: City.byCode(n[2]),
          homeBase: _bases[i % _bases.length],
          intro: i == 12
              ? null // 髒資料 ②：缺介紹
              : '${City.byCode(n[2]).zh}的${styles.first.zh}運動社團，歡迎各種程度的夥伴一起參加。'
                  '我們每週固定團練，重視安全與陪伴，不留任何人在後面。',
          regularSchedule: i.isEven ? '每週三 19:30、每週六 07:00' : null,
          activityScore: 24 - i + _rnd.nextInt(6),
          styles: styles.toList(),
          instagramUrl: hasIg
              ? 'https://www.instagram.com/${n[1].toLowerCase().replaceAll(' ', '')}/'
              : null,
          createdAt: now.subtract(Duration(days: i < 6 ? 5 + i * 3 : 60 + i * 11)),
        ),
      );
    }
    out.sort((a, b) => b.activityScore.compareTo(a.activityScore));
    return out;
  }

  Map<String, List<Session>> _buildSessions() {
    final map = <String, List<Session>>{};
    for (final crew in crews) {
      final idx = int.parse(crew.id.split('-')[1]);
      // 髒資料 ③：index 20 完全沒有活動
      if (idx == 20) {
        map[crew.id] = const <Session>[];
        continue;
      }
      final list = <Session>[];
      // 髒資料 ④：index 3 只有過往活動（本月未公告）
      final futureCount = idx == 3 ? 0 : 3 + _rnd.nextInt(5);
      final pastCount = 2 + _rnd.nextInt(4);

      for (var k = 0; k < futureCount; k++) {
        list.add(_session(crew, k, idx, future: true, index: k));
      }
      for (var k = 0; k < pastCount; k++) {
        list.add(_session(crew, k, idx, future: false, index: k));
      }
      // 髒資料 ⑤：第一個社團加一場跨午夜的活動（22:00 → 隔日 01:00）
      if (idx == 0) {
        final base = _dateOnly(now).add(const Duration(days: 2));
        list.add(
          Session(
            id: '${crew.id}-midnight',
            crewId: crew.id,
            title: '午夜長征 Midnight Ultra',
            kind: SessionKind.special,
            startsAt: base.add(const Duration(hours: 22)),
            endsAt: base.add(const Duration(hours: 25)),
            locationName: '河濱公園自行車道起點',
          ),
        );
      }
      list.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      map[crew.id] = list;
    }
    return map;
  }

  Session _session(Crew crew, int k, int crewIdx,
      {required bool future, required int index}) {
    final dayOffset = future ? 1 + k * 3 + _rnd.nextInt(3) : -(2 + k * 4);
    final day = _dateOnly(now).add(Duration(days: dayOffset));
    final isWeekend = day.weekday >= DateTime.saturday;
    // 真實時間分布：週末早上、平日晚上
    final start = isWeekend
        ? day.add(Duration(hours: 6 + _rnd.nextInt(3), minutes: _rnd.nextBool() ? 0 : 30))
        : day.add(Duration(hours: 19, minutes: _rnd.nextBool() ? 0 : 30));
    final kind = index == 0 && crewIdx.isEven
        ? SessionKind.special
        : (isWeekend ? SessionKind.social : SessionKind.regular);
    return Session(
      id: '${crew.id}-s$index-${future ? 'f' : 'p'}',
      crewId: crew.id,
      title: _titles[(crewIdx + index) % _titles.length],
      kind: kind,
      startsAt: start,
      endsAt: start.add(Duration(minutes: 60 + _rnd.nextInt(4) * 30)),
      locationName: _bases[(crewIdx + index) % _bases.length],
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _slug(String handle, int i) =>
      '${handle.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-')}-$i';
}
