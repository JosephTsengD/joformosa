// @spec T-042/Scenario-AppBoots
//
// 這是「能不能 demo」的最短證明：把真正的 main() 會建立的 widget 樹
// 完整跑一次，不 mock 任何畫面。它會抓到 provider 圖接錯、路由設定錯、
// 主題 extension 忘了註冊、初始狀態渲染爆炸這幾類問題——
// 那些正是 demo 當場黑畫面的原因。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joincrew/app/app.dart';
import 'package:joincrew/app/providers.dart';
import 'package:joincrew/core/l10n/strings.dart';
import 'package:joincrew/core/utils/clock.dart';
import 'package:joincrew/features/crew_discovery/data/fake_crew_repository.dart';
import 'package:joincrew/features/crew_discovery/presentation/crew_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const s = Strings('zh-Hant');
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> boot(WidgetTester tester, {bool fail = false, bool empty = false}) async {
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
        child: const JoinCrewApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('App 啟動後探索頁渲染出社團卡片', (WidgetTester tester) async {
    await boot(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('JoinCrew'), findsOneWidget);
    expect(find.byType(CrewCard), findsWidgets);
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
    await tester.tap(find.byType(CrewCard).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(s.upcoming), findsOneWidget);
    expect(find.text(s.openInstagram), findsOneWidget);
  });

  testWidgets('深色模式下整棵樹不拋錯', (WidgetTester tester) async {
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
        child: const JoinCrewApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
