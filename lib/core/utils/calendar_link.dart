import '../../features/crew_discovery/domain/entities.dart';

/// 把活動轉成「加入行事曆」的連結與 ICS 內容。
///
/// 為什麼主要走 Google Calendar 連結，而不是下載 .ics 檔？
/// ─────────────────────────────────────────────────────────
/// .ics 在 web 上的體驗很差：瀏覽器可能直接顯示純文字而非下載，
/// 檔名無法可靠控制，iOS Safari 的處理方式又不一樣。
/// 而 Google Calendar 的 template URL 只是一個網址——
/// 三個平台的行為完全一致，也不需要處理檔案權限。
///
/// ICS 仍然保留（`buildIcs`），因為行動裝置的原生分享需要它，
/// 而且它是純函式，測試成本幾乎為零。
abstract final class CalendarLink {
  /// Google Calendar 的時間格式：YYYYMMDDTHHMMSSZ，**必須是 UTC**。
  /// 傳本地時間而不加 Z，Google 會用「使用者行事曆的時區」解讀，
  /// 於是台灣的 19:30 在別人那裡變成別的時間。
  static String formatUtc(DateTime t) {
    final u = t.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${u.year}${two(u.month)}${two(u.day)}'
        'T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  static DateTime _endOf(Session s) => s.effectiveEnd;

  static String googleCalendarUrl({
    required Session session,
    required String crewName,
    String? crewUrl,
  }) {
    final details = <String>[
      '$crewName 的團練活動',
      if (crewUrl != null) '社團頁面：$crewUrl',
      '',
      '活動如遇天氣等即時因素異動，請以社團官方帳號最新公告為準。',
    ].join('\n');

    return Uri.https('calendar.google.com', '/calendar/render', <String, String>{
      'action': 'TEMPLATE',
      'text': '${session.title}｜$crewName',
      'dates': '${formatUtc(session.startsAt)}/${formatUtc(_endOf(session))}',
      'location': session.locationName,
      'details': details,
    }).toString();
  }

  /// ICS（RFC 5545）。行動裝置分享與未來的批次匯出用。
  static String buildIcs({
    required Session session,
    required String crewName,
    required DateTime now,
  }) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//JoFormosa//TW//ZH',
      'CALSCALE:GREGORIAN',
      'BEGIN:VEVENT',
      'UID:${session.id}@joformosa',
      'DTSTAMP:${formatUtc(now)}',
      'DTSTART:${formatUtc(session.startsAt)}',
      'DTEND:${formatUtc(_endOf(session))}',
      'SUMMARY:${escape('${session.title}｜$crewName')}',
      'LOCATION:${escape(session.locationName)}',
      'END:VEVENT',
      'END:VCALENDAR',
    ];
    // RFC 5545 要求 CRLF。只用 \n 的話部分行事曆軟體會整份拒絕，
    // 而且錯誤訊息通常只說「格式無效」。
    return '${lines.join('\r\n')}\r\n';
  }

  /// ICS 的跳脫規則：反斜線要先跳脫，否則會把後面加上的反斜線再跳脫一次。
  static String escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');
}
