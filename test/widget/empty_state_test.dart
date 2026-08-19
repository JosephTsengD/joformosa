// @spec T-042/Scenario-EmptyStateFits
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/core/theme/app_theme.dart';
import 'package:joformosa/core/widgets/primitives.dart';

/// 空狀態的高度不固定（語言、字級都會改變它），
/// 可用高度也不固定（裝置、橫向、鍵盤）。
/// 兩邊都會動的時候，必須驗證極端組合不會溢位。
void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      );

  const view = EmptyStateView(
    icon: Icons.search_off_rounded,
    title: '找不到「大安森林公園晨跑團」',
    hint: '試試看社團名稱的一部分，或改用縣市與風格篩選。',
    actionLabel: '清除搜尋',
  );

  Future<void> pumpAt(WidgetTester tester, Size size, double scale) async {
    tester.view
      ..physicalSize = Size(size.width * 3, size.height * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: view,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('一般手機直向不溢位', (WidgetTester tester) async {
    await pumpAt(tester, const Size(390, 844), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('手機橫向（可用高度極小）不溢位', (WidgetTester tester) async {
    // 這是原本會炸的情境：高度只有 390
    await pumpAt(tester, const Size(844, 390), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('小螢幕加 2.0 字級不溢位', (WidgetTester tester) async {
    await pumpAt(tester, const Size(320, 568), 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('空間不足時內容可捲動而非被裁掉', (WidgetTester tester) async {
    await pumpAt(tester, const Size(320, 320), 2);
    expect(tester.takeException(), isNull);

    // 可捲動代表內容還在，只是需要捲動才看得完；
    // 若是被裁掉或溢位，使用者永遠碰不到那顆按鈕
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
