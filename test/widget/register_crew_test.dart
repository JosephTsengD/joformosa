// @spec T-060/Scenario-UnsavedGuard
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joformosa/app/providers.dart';
import 'package:joformosa/core/l10n/strings.dart';
import 'package:joformosa/core/theme/app_theme.dart';
import 'package:joformosa/core/utils/clock.dart';
import 'package:joformosa/features/crew_admin/presentation/register_crew_screen.dart';
import 'package:joformosa/features/crew_discovery/data/fake_crew_repository.dart';

void main() {
  const s = Strings('zh-Hant');

  /// RegisterCrewScreen 會呼叫 `context.go('/admin')`。
  /// 用 MaterialApp(home:) 掛載時 GoRouter 不在 widget tree 中，
  /// 點擊關閉會拋 GoError——測試必須提供真正的 router。
  Future<void> pump(WidgetTester tester) {
    final router = GoRouter(
      initialLocation: '/admin/register',
      routes: <RouteBase>[
        GoRoute(
          path: '/admin',
          builder: (BuildContext _, GoRouterState __) =>
              const Scaffold(body: Text('admin-stub')),
          routes: <RouteBase>[
            GoRoute(
              path: 'register',
              builder: (BuildContext _, GoRouterState __) => const RegisterCrewScreen(),
            ),
          ],
        ),
      ],
    );
    return tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          clockProvider.overrideWithValue(FakeClock(DateTime(2026, 8, 12, 10))),
          crewRepositoryProvider.overrideWithValue(
            FakeCrewRepository(
              FakeClock(DateTime(2026, 8, 12, 10)),
              latency: Duration.zero,
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }

  /// 捲動到目標 widget 出現為止。
  ///
  /// 為什麼不能直接用 `tester.scrollUntilVisible(finder, delta)`？
  /// 它預設會去找畫面上唯一的 Scrollable，而**每個 TextField 內部都有一個
  /// Scrollable**（EditableText 用它處理單行捲動）。這個表單有六個輸入框，
  /// 於是 finder 一次找到七個，拋出 `Bad state: Too many elements`。
  ///
  /// 正解是明確指定要捲哪一個：外層的 ListView。
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.dragUntilVisible(
      target,
      find.byType(ListView),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('未修改時關閉直接離開，不顯示警告', (WidgetTester tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text(s.unsavedWarning), findsNothing);
    expect(find.text('admin-stub'), findsOneWidget);
  });

  testWidgets('已修改後關閉會顯示未儲存警告，且停留在表單', (WidgetTester tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).first, '測試跑團');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text(s.unsavedWarning), findsOneWidget);
    expect(find.text('admin-stub'), findsNothing);
  });

  testWidgets('警告對話框選擇取消後回到表單', (WidgetTester tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).first, '測試跑團');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, s.cancel));
    await tester.pumpAndSettle();

    expect(find.text(s.unsavedWarning), findsNothing);
    expect(find.text('admin-stub'), findsNothing);
  });

  testWidgets('未勾選同意條款時送出按鈕為停用', (WidgetTester tester) async {
    await pump(tester);

    final submitFinder = find.widgetWithText(FilledButton, s.submit);
    await scrollTo(tester, submitFinder);

    expect(submitFinder, findsOneWidget);
    final FilledButton button = tester.widget(submitFinder);
    expect(button.onPressed, isNull, reason: '未勾選同意條款時應為停用');
  });

  testWidgets('勾選同意條款後送出按鈕啟用', (WidgetTester tester) async {
    await pump(tester);

    final consentFinder = find.byType(Checkbox);
    await scrollTo(tester, consentFinder);
    await tester.tap(consentFinder);
    await tester.pumpAndSettle();

    final submitFinder = find.widgetWithText(FilledButton, s.submit);
    await scrollTo(tester, submitFinder);

    final FilledButton button = tester.widget(submitFinder);
    expect(button.onPressed, isNotNull);
  });
}
