import '../l10n/strings.dart';
import '../../features/crew_discovery/domain/entities.dart';

/// 時間格式規則（計劃書 7.1）：一律「相對 + 絕對」雙寫。
/// 「今晚 19:30」比「8/13 19:30」更容易被掃描。
class TimeFormatter {
  const TimeFormatter(this.s);
  final Strings s;

  static String hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String md(DateTime d) => '${d.month}/${d.day}';

  static const _weekdayZh = <String>['一', '二', '三', '四', '五', '六', '日'];
  static const _weekdayEn = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String weekday(DateTime d, {required bool zh}) =>
      zh ? _weekdayZh[d.weekday - 1] : _weekdayEn[d.weekday - 1];

  static const _monthEn = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  static String monthShort(DateTime d) => _monthEn[d.month - 1];

  bool get _zh => s.locale.startsWith('zh');

  /// 「今晚 19:30」/「明天 07:00」/「8/22（六）07:30」
  String relative(DateTime target, DateTime now) {
    final days = _dayDiff(target, now);
    final time = hhmm(target);
    if (days == 0) {
      final isEvening = target.hour >= 17;
      return '${isEvening ? s.tonight : s.today} $time';
    }
    if (days == 1) {
      return '${s.tomorrow} $time';
    }
    if (days > 1 && days <= 6) {
      return _zh
          ? '週${weekday(target, zh: true)} $time'
          : '${weekday(target, zh: false)} $time';
    }
    return _zh
        ? '${md(target)}（${weekday(target, zh: true)}） $time'
        : '${md(target)} ${weekday(target, zh: false)} $time';
  }

  /// 「8/22（六）07:30–10:30｜地點」
  String fullRange(Session session) {
    final start = session.startsAt;
    final buf = StringBuffer()
      ..write(_zh
          ? '${md(start)}（${weekday(start, zh: true)}）'
          : '${md(start)} ${weekday(start, zh: false)}')
      ..write(' ')
      ..write(hhmm(start));
    if (session.endsAt != null) {
      buf.write('–${hhmm(session.endsAt!)}');
    }
    buf.write('｜${session.locationName}');
    return buf.toString();
  }

  String ago(Duration d) {
    if (d.inMinutes < 1) {
      return _zh ? '剛剛' : 'moments';
    }
    if (d.inMinutes < 60) {
      return _zh ? '${d.inMinutes} 分鐘' : '${d.inMinutes} min';
    }
    if (d.inHours < 24) {
      return _zh ? '${d.inHours} 小時' : '${d.inHours} hr';
    }
    return _zh ? '${d.inDays} 天' : '${d.inDays} d';
  }

  /// **不用 difference().inDays**：那是絕對 24 小時差，
  /// 會讓「今天 23:00」與「明天 01:00」被判定為同一天（差 2 小時）。
  /// 必須先歸零到日界線再比。
  static int _dayDiff(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return da.difference(db).inDays;
  }
}

String sportLabel(Sport s, Strings str) => switch (s) {
      Sport.run => str.sportRun,
      Sport.ride => str.sportRide,
      Sport.hyrox => str.sportHyrox,
      Sport.other => str.sportOther,
    };

String sportLabelEn(Sport s) => switch (s) {
      Sport.run => 'RUN',
      Sport.ride => 'RIDE',
      Sport.hyrox => 'HYROX',
      Sport.other => 'OTHER',
    };

String sessionKindLabel(SessionKind k, Strings s) => switch (k) {
      SessionKind.regular => s.kindRegular,
      SessionKind.special => s.kindSpecial,
      SessionKind.race => s.kindRace,
      SessionKind.social => s.kindSocial,
    };
