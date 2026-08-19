// @spec T-042/Scenario-FilterUrlSync
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/features/crew_discovery/domain/entities.dart';

void main() {
  test('篩選狀態 ↔ URL query 可雙向轉換（Web 可分享搜尋結果）', () {
    // 不能用 const：StyleTag 覆寫了 ==，而 Dart 禁止 const 集合的
    // 元素型別覆寫 ==（常數去重必須在編譯期完成）。
    final filter = CrewFilter(
      sport: Sport.run,
      city: City.taichung,
      styles: <StyleTag>{StyleTag.beginner, StyleTag.night},
      query: 'dawn',
      sort: CrewSort.nextSession,
    );

    final params = filter.toQueryParams();
    final back = CrewFilter.fromQueryParams(params);

    expect(back.sport, filter.sport);
    expect(back.city, filter.city);
    expect(back.styles, filter.styles);
    expect(back.query, filter.query);
    expect(back.sort, filter.sort);
  });

  test('空篩選不產生任何 query 參數', () {
    expect(const CrewFilter().toQueryParams(), isEmpty);
    expect(const CrewFilter().isEmpty, isTrue);
  });

  test('activeCount 正確計數', () {
    final f = CrewFilter(
      sport: Sport.ride,
      styles: <StyleTag>{StyleTag.trail, StyleTag.social},
    );
    expect(f.activeCount, 3);
  });
}
