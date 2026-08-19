// @spec T-042/Scenario-AppBoots
// @spec T-042/Scenario-NoGlobalNavState
//
// 這是「能不能 demo」的最短證明：把真正的 main() 會建立的 widget 樹
// 完整跑一次，不 mock 任何畫面。它會抓到 provider 圖接錯、路由設定錯、
// 主題 extension 忘了註冊、初始狀態渲染爆炸這幾類問題——
// 那些正是 demo 當場黑畫面的原因。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/app/app.dart';
import 'package:joformosa/app/providers.dart';
import 'package:joformosa/core/l10n/strings.dart';
import 'package:joformosa/core/utils/clock.dart';
import 'package:joformosa/features/crew_discovery/data/fake_crew_repository.dart';
import 'package:joformosa/features/crew_discovery/presentation/crew_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const s = Strings('zh-Hant');
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  /// 用真實手機尺寸，不是 flutter_test 預設的 800×600。
  ///
  /// 預設值又矮又寬，沒有任何真實裝置長那樣。它會造成兩種假失敗：
  /// 1. 版面在測試中溢位，但實機完全正常
  /// 2. 元件被 pinned header 蓋住，tap 打不到目標
  /// 反過來也會漏掉真實的窄螢幕問題，因為 800 太寬了。
  void useIPhoneViewport(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> boot(WidgetTester tester, {bool fail = false, bool empty = false}) async {
    useIPhoneViewport(tester);
    final clock = FakeClock(DateTime(2026, 8, 12, 10));
    final repo = FakeCrewRepository(clock, latency: Duration.zero)
      ..simulateFailure = fail
      ..simulateEmpty = empty;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPrefsProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(clock),
          crewRepositoryProvider.overrideWithValue(repo),
        ],
        child: const JoFormosaApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('App 啟動後探索頁渲染出社團卡片', (WidgetTester tester) async {
    await boot(tester);
    expect(tester.takeException(), isNull);
    // 用 Strings 而非硬編字面值：品牌改名時測試才不會一起腐爛
    expect(find.text(s.appName), findsOneWidget);
    expect(find.byType(CrewCard), findsWidgets);
  });

  testWidgets('搜尋框存在且可輸入', (WidgetTester tester) async {
    await boot(tester);
    final field = find.byType(TextField);
    expect(field, findsWidgets);

    await tester.enterText(field.first, '晨光');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.byType(CrewCard), findsWidgets);
  });

  testWidgets('搜尋落空時顯示含關鍵字的空狀態', (WidgetTester tester) async {
    await boot(tester);
    await tester.enterText(find.byType(TextField).first, '絕對不存在的社團xyz');
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text(s.searchClear), findsOneWidget);
  });

  testWidgets('示範橫幅在首次進入時顯示', (WidgetTester tester) async {
    await boot(tester);
    expect(find.text(s.demoBadge), findsOneWidget);
  });

  testWidgets('後端失敗時顯示錯誤狀態與重試，而不是白畫面', (WidgetTester tester) async {
    await boot(tester, fail: true);
    expect(tester.takeException(), isNull);
    expect(find.text(s.errorNetwork), findsOneWidget);
    expect(find.text(s.retry), findsOneWidget);
  });

  testWidgets('沒有結果時顯示空狀態文案，而不是空白列表', (WidgetTester tester) async {
    await boot(tester, empty: true);
    expect(tester.takeException(), isNull);
    expect(find.text(s.emptyNoResult), findsOneWidget);
  });

  testWidgets('點卡片可導覽到詳情頁並顯示活動時間軸', (WidgetTester tester) async {
    await boot(tester);

    // pinned header 有 152dp 高。不先 ensureVisible 的話，
    // 第一張卡片的中心點可能落在 header 底下，tap 會打到 header。
    final firstCard = find.byType(CrewCard).first;
    await tester.ensureVisible(firstCard);
    await tester.pumpAndSettle();

    await tester.tap(firstCard);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(s.upcoming), findsOneWidget);
    expect(find.text(s.openInstagram), findsOneWidget);
  });

  testWidgets('前一次搜尋不會污染下一次啟動（測試隔離）', (WidgetTester tester) async {
    // 這條專門守住一個真實 bug：router 曾經是頂層單例，
    // 導覽位置留在裡面，導致「單獨跑會過、一起跑會失敗」。
    await boot(tester);
    await tester.enterText(find.byType(TextField).first, '絕對不存在xyz');
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(find.text(s.searchClear), findsOneWidget);

    // 重新啟動一次 App：必須回到乾淨狀態
    await boot(tester);

    expect(find.byType(CrewCard), findsWidgets, reason: '不該繼承上次的空結果');
    expect(find.text(s.searchClear), findsNothing, reason: '不該繼承上次的搜尋字');
  });

  testWidgets('深色模式下整棵樹不拋錯', (WidgetTester tester) async {
    useIPhoneViewport(tester);
    final clock = FakeClock(DateTime(2026, 8, 12, 10));
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPrefsProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(clock),
          crewRepositoryProvider.overrideWithValue(
            FakeCrewRepository(clock, latency: Duration.zero),
          ),
          themeModeProvider.overrideWith((Ref ref) => ThemeMode.dark),
        ],
        child: const JoFormosaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
