/// 手寫型別安全字典（零 code-gen，clone 即可執行）。
/// 遷移到官方 ARB 是 task T-070。
///
/// 規則：widget 中**禁止**出現硬編碼的使用者可見中文字串。
class Strings {
  const Strings(this.locale);
  final String locale;

  bool get _zh => locale.startsWith('zh');

  /// 品牌名：中文「揪Formosa」，英文「JoFormosa」。
  /// 中文語境保留 Formosa 的原字，不譯成「福爾摩沙」——
  /// 前者是刻意的混語品牌，後者只是音譯。
  String get appName => _zh ? '揪Formosa' : 'JoFormosa';
  String get tagline => _zh ? '運動找隊？來揪隊。' : 'Find your sports crew.';

  String get navDiscover => _zh ? '探索' : 'Discover';
  String get navFavorites => _zh ? '收藏' : 'Saved';
  String get navMe => _zh ? '我的' : 'Me';

  String get sportAll => _zh ? '全部' : 'All';
  String get sportRun => _zh ? '跑步' : 'Run';
  String get sportRide => _zh ? '自行車' : 'Ride';
  String get sportHyrox => 'HYROX';
  String get sportOther => _zh ? '其他' : 'Other';

  String get searchHint => _zh ? '搜尋社團名稱、地點、風格' : 'Search crews, places, styles';
  String get searchClear => _zh ? '清除搜尋' : 'Clear search';
  String get searchRecent => _zh ? '最近搜尋' : 'Recent';
  String get searchRecentClear => _zh ? '清除紀錄' : 'Clear history';
  String searchEmptyTitle(String q) => _zh ? '找不到「$q」' : 'No results for “$q”';
  String get searchEmptyHint => _zh
      ? '試試看社團名稱的一部分，或改用縣市與風格篩選。'
      : 'Try part of the name, or filter by city and style.';
  String get searchCancel => _zh ? '取消' : 'Cancel';

  String get filterCity => _zh ? '縣市' : 'City';
  String get filterStyle => _zh ? '風格' : 'Style';
  String get filterClear => _zh ? '清除' : 'Clear';
  String get filterApply => _zh ? '查看結果' : 'Show results';
  String filterResultCount(int n) => _zh ? '查看 $n 個結果' : 'Show $n results';
  String filterActive(int n) => _zh ? '篩選 $n' : 'Filters $n';

  String get whenAny => _zh ? '不限時間' : 'Any time';
  String get whenToday => _zh ? '今天' : 'Today';
  String get whenThisWeek => _zh ? '本週' : 'This week';
  String get whenWeekend => _zh ? '這週末' : 'Weekend';
  String get filterWhen => _zh ? '時間' : 'When';
  String get calendarAdded => _zh ? '已開啟行事曆' : 'Opening calendar';
  String get calendarFailed => _zh ? '無法開啟行事曆' : 'Could not open calendar';

  String get sortByScore => _zh ? '活躍度' : 'Activity';
  String get sortByNext => _zh ? '最近開團' : 'Next session';

  String get upcoming => _zh ? '即將到來' : 'Upcoming';
  String get past => _zh ? '過往活動' : 'Past';
  String get today => _zh ? '今天' : 'Today';
  String get tonight => _zh ? '今晚' : 'Tonight';
  String get tomorrow => _zh ? '明天' : 'Tomorrow';
  String get ongoing => _zh ? '進行中' : 'Ongoing';
  String get ended => _zh ? '已結束' : 'Ended';
  String get noSessions => _zh ? '尚未公告本月活動' : 'No sessions announced yet';

  String get scoreLabel => _zh ? '活躍度' : 'Activity';
  String get scoreUpdatedNote => _zh ? '每週一 12:00 更新' : 'Updated Mondays 12:00';
  String get scoreBreakdown => _zh ? '積分明細' : 'Score breakdown';

  String get disclaimer => _zh
      ? '活動如遇天氣等即時因素異動，請以社團官方帳號最新公告為準。'
      : 'Session changes follow each crew\u2019s official posts.';

  String get openInstagram => _zh ? '前往官方 IG' : 'Open Instagram';
  String get save => _zh ? '收藏' : 'Save';
  String get saved => _zh ? '已收藏' : 'Saved';
  String get share => _zh ? '分享' : 'Share';
  String get remind => _zh ? '提醒我' : 'Remind me';
  String get addToCalendar => _zh ? '加入行事曆' : 'Add to calendar';

  String get emptyNoResult => _zh ? '找不到符合的社團' : 'No crews match';
  String get emptyNoResultHint =>
      _zh ? '試著放寬篩選條件，或看看其他縣市。' : 'Try relaxing your filters.';
  String get emptyNoFavorites => _zh ? '還沒有收藏的社團' : 'No saved crews yet';
  String get emptyNoFavoritesHint =>
      _zh ? '在探索頁長按卡片即可快速收藏。' : 'Long-press a card to save it.';
  String get allLoaded => _zh ? '已顯示全部' : 'That\u2019s everything';

  String get retry => _zh ? '重試' : 'Retry';
  String get errorNetwork => _zh ? '網路連線有問題' : 'Network problem';
  String get errorTimeout => _zh ? '連線逾時' : 'Request timed out';
  String get errorNotFound => _zh ? '找不到這個社團' : 'Crew not found';
  String get errorAuth => _zh ? '請重新登入' : 'Please sign in again';
  String get errorValidation => _zh ? '請檢查欄位內容' : 'Please check the fields';
  String get errorRateLimit => _zh ? '請求太頻繁，請稍候' : 'Too many requests';
  String get errorUnknown => _zh ? '發生未預期的錯誤' : 'Something went wrong';

  String staleBanner(String ago) => _zh ? '顯示的是 $ago 前的資料' : 'Showing data from $ago ago';
  String get refreshNow => _zh ? '重新整理' : 'Refresh';
  String get offline => _zh ? '離線模式' : 'Offline';

  String get signIn => _zh ? '登入' : 'Sign in';
  String get signInWithLine => _zh ? '使用 LINE 登入' : 'Continue with LINE';
  String get signInBenefit =>
      _zh ? '登入後可收藏社團、設定活動提醒，並在換裝置時同步。' : 'Sign in to save crews and sync.';
  String get lineSigningIn => _zh ? '正在完成登入…' : 'Signing you in…';

  /// 把技術性的失敗代碼翻成使用者看得懂、而且**知道下一步該做什麼**的話。
  /// 直接顯示 state_mismatch 對使用者毫無意義。
  String lineErrorHint(String reason) => switch (reason) {
        'stateMismatch' => _zh
            ? '這次登入的驗證資訊不符，為了安全已中止。請重新登入一次。'
            : 'Verification failed for security reasons. Please sign in again.',
        'noPendingRequest' =>
          _zh ? '找不到進行中的登入流程。請回到登入頁重新開始。' : 'No sign-in in progress. Please start again.',
        'missingCode' =>
          _zh ? 'LINE 沒有回傳授權碼，請重新登入一次。' : 'LINE did not return an authorization code.',
        'line_not_configured' =>
          _zh ? '這個環境尚未設定 LINE 登入。' : 'LINE login is not configured in this environment.',
        'exchange_failed' =>
          _zh ? '無法完成登入，請稍後再試。' : 'Could not complete sign-in. Please try again.',
        _ => _zh ? '登入未完成，請再試一次。' : 'Sign-in did not complete.',
      };

  String get signOut => _zh ? '登出' : 'Sign out';
  String get browseAsGuest => _zh ? '先逛逛就好' : 'Browse as guest';
  String get guestUser => _zh ? '訪客' : 'Guest';

  String get adminTitle => _zh ? '團長後台' : 'Crew admin';
  String get adminMyCrew => _zh ? '我的社團' : 'My crew';
  String get adminNewSession => _zh ? '新增活動' : 'New session';
  String get adminSubmitCrew => _zh ? '登錄社團' : 'Register crew';
  String get adminNoCrewYet => _zh ? '你還沒有社團' : 'No crew yet';
  String get adminNoCrewHint =>
      _zh ? '登錄後需每月依制式表格填寫社團活動，日期／時間／地點為必填。' : 'Monthly session reporting is required.';

  String get fieldCrewName => _zh ? '社團名稱' : 'Crew name';
  String get fieldSport => _zh ? '運動類別' : 'Sport';
  String get fieldCity => _zh ? '所在縣市' : 'City';
  String get fieldHomeBase => _zh ? '主要據點／集合區域' : 'Home base';
  String get fieldSchedule => _zh ? '固定團練時間' : 'Regular schedule';
  String get fieldStyles => _zh ? '風格標籤（可複選）' : 'Style tags';
  String get fieldIntro => _zh ? '社團介紹' : 'Intro';
  String get fieldInstagram => 'Instagram';
  String get fieldContactName => _zh ? '聯絡人稱呼' : 'Contact name';
  String get fieldSessionTitle => _zh ? '活動名稱' : 'Session title';
  String get fieldStartsAt => _zh ? '開始時間' : 'Starts at';
  String get fieldEndsAt => _zh ? '結束時間（選填）' : 'Ends at (optional)';
  String get fieldLocation => _zh ? '地點' : 'Location';
  String get fieldSessionKind => _zh ? '活動類型' : 'Session type';
  String get required => _zh ? '必填' : 'Required';
  String get submit => _zh ? '送出' : 'Submit';
  String get saveChanges => _zh ? '儲存' : 'Save';
  String get cancel => _zh ? '取消' : 'Cancel';
  String get delete => _zh ? '刪除' : 'Delete';
  String get submitting => _zh ? '送出中…' : 'Submitting…';
  String get submitSuccess => _zh ? '已送出，審核後會通知你' : 'Submitted for review';
  String get sessionCreated => _zh ? '活動已新增' : 'Session created';
  String get unsavedWarning => _zh ? '有未儲存的變更，確定要離開嗎？' : 'Discard unsaved changes?';
  String get consentText => _zh
      ? '我了解並同意：入駐後需每月填寫社團活動；活躍度積分依平台規則計算並公開。'
      : 'I agree to report monthly sessions and to the public scoring rules.';

  String get demoBadge => _zh ? '示範資料' : 'Demo data';
  String get demoBannerBody => _zh
      ? '這是技術展示專案，所有社團為虛構資料。你可以實際登錄社團與新增活動，送出後會進入審核佇列。'
      : 'Technical showcase with fictional crews. Submissions go to a review queue.';
  String get statusPending => _zh ? '審核中' : 'Under review';
  String get statusPendingHint => _zh
      ? '你的社團已送出，審核通過後才會出現在公開列表。你仍可先新增活動。'
      : 'Submitted. It will appear publicly once approved.';
  String get degradedBanner =>
      _zh ? '目前連不上伺服器，顯示的是離線示範資料' : 'Server unreachable — showing offline demo data';

  String get demoReset => _zh ? '重置示範資料' : 'Reset demo data';
  String get demoResetConfirm =>
      _zh ? '將清除你在此裝置建立的社團與活動，確定嗎？' : 'Clear everything you created on this device?';
  String get demoResetDone => _zh ? '已回到初始狀態' : 'Reset to initial state';
  String get demoDismiss => _zh ? '知道了' : 'Got it';

  String get moderationTitle => _zh ? '審核佇列' : 'Review queue';
  String get moderationEmpty => _zh ? '沒有待審核的社團' : 'Nothing to review';
  String get moderationEmptyHint =>
      _zh ? '使用者送出的社團會出現在這裡，核准後才會進入公開列表。' : 'Submissions appear here.';
  String get moderationForbidden => _zh ? '沒有存取權限' : 'Access denied';
  String get moderationForbiddenHint =>
      _zh ? '這個頁面僅限管理員。若你認為這是錯誤，請聯繫平台。' : 'Admins only.';
  String get moderationApprove => _zh ? '核准' : 'Approve';
  String get moderationReject => _zh ? '拒絕' : 'Reject';
  String get moderationReason => _zh ? '拒絕理由' : 'Reason';
  String get moderationReasonRequired =>
      _zh ? '拒絕時必須填寫理由，送出者會看到它' : 'A reason is required';
  String get moderationApproved => _zh ? '已核准並發布' : 'Approved and published';
  String get moderationRejected => _zh ? '已拒絕' : 'Rejected';
  String get moderationAudit => _zh ? '稽核紀錄' : 'Audit log';
  String get moderationAuditEmpty => _zh ? '尚無紀錄' : 'No entries yet';
  String moderationPendingCount(int n) => _zh ? '待審核 $n' : '$n pending';

  String get kindRegular => _zh ? '一般團練' : 'Regular';
  String get kindSpecial => _zh ? '特別活動' : 'Special';
  String get kindRace => _zh ? '賽事' : 'Race';
  String get kindSocial => _zh ? '社交跑' : 'Social';

  String errorOf(String key) => switch (key) {
        'error.network' => errorNetwork,
        'error.timeout' => errorTimeout,
        'error.notFound' => errorNotFound,
        'error.auth' => errorAuth,
        'error.validation' => errorValidation,
        'error.rateLimit' => errorRateLimit,
        _ => errorUnknown,
      };
}
