// @spec T-042/Scenario-CardStates
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/core/l10n/strings.dart';
import 'package:joformosa/core/theme/app_theme.dart';
import 'package:joformosa/features/crew_discovery/domain/entities.dart';
import 'package:joformosa/features/crew_discovery/presentation/crew_card.dart';

void main() {
  final now = DateTime(2026, 8, 12, 10);

  Crew crew({
    String name = '晨光跑者',
    int score = 21,
    DateTime? created,
    Session? next,
    List<StyleTag> styles = const <StyleTag>[StyleTag.beginner],
  }) =>
      Crew(
        id: 'c1',
        slug: 'c1',
        name: name,
        sport: Sport.run,
        city: City.taipei,
        homeBase: '大安森林公園',
        activityScore: score,
        styles: styles,
        nextSession: next,
        createdAt: created ?? DateTime(2026, 8, 1),
      );

  Future<void> pump(WidgetTester tester, Crew c, {bool fav = false}) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: CrewCard(
              crew: c,
              now: now,
              strings: const Strings('zh-Hant'),
              isFavorite: fav,
              onTap: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

  testWidgets('30 天內建立的社團顯示 NEW 徽章', (WidgetTester tester) async {
    await pump(tester, crew(created: DateTime(2026, 8, 1)));
    expect(find.text('NEW'), findsOneWidget);
  });

  testWidgets('超過 30 天不顯示 NEW', (WidgetTester tester) async {
    await pump(tester, crew(created: DateTime(2026, 1, 1)));
    expect(find.text('NEW'), findsNothing);
  });

  testWidgets('沒有活動時顯示「尚未公告本月活動」而非空白', (WidgetTester tester) async {
    await pump(tester, crew());
    expect(find.text(const Strings('zh-Hant').noSessions), findsOneWidget);
  });

  testWidgets('超長社團名稱單行省略且不溢位', (WidgetTester tester) async {
    await pump(
      tester,
      crew(name: '台北山徑越野俱樂部 Taipei Trail Explorers Club 超長名稱測試用'),
    );
    expect(tester.takeException(), isNull);
    final Text title = tester.widget(find.textContaining('台北山徑越野俱樂部'));
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
  });

  testWidgets('textScaleFactor 2.0 不破版', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: CrewCard(
              crew: crew(),
              now: now,
              strings: const Strings('zh-Hant'),
              isFavorite: false,
              onTap: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('已收藏時顯示實心愛心', (WidgetTester tester) async {
    await pump(tester, crew(), fav: true);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });
}
