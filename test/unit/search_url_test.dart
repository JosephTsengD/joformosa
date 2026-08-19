// @spec T-070/Scenario-SearchUrlSync
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/features/crew_discovery/domain/entities.dart';

void main() {
  test('搜尋關鍵字會進入網址', () {
    const filter = CrewFilter(query: '夜跑');
    final location = filter.toLocation();

    expect(location, contains('q='));
    final restored = CrewFilter.fromQueryParams(
      Uri.parse(location).queryParameters,
    );
    expect(restored.query, '夜跑');
  });

  test('搜尋加篩選一起往返後完全相同', () {
    final filter = CrewFilter(
      query: '河濱',
      sport: Sport.run,
      city: City.taichung,
      styles: <StyleTag>{StyleTag.night},
      sort: CrewSort.nextSession,
    );

    final restored = CrewFilter.fromQueryParams(
      Uri.parse(filter.toLocation()).queryParameters,
    );

    expect(restored.query, filter.query);
    expect(restored.sport, filter.sport);
    expect(restored.city, filter.city);
    expect(restored.styles, filter.styles);
    expect(restored.sort, filter.sort);
  });

  test('空篩選產生乾淨的根路徑，不是帶問號的空查詢字串', () {
    expect(const CrewFilter().toLocation(), '/');
  });

  test('中文與空白正確編碼，不會產生壞網址', () {
    const filter = CrewFilter(query: '大安 森林');
    final location = filter.toLocation();

    // 直接串字串的話這裡會壞掉
    expect(() => Uri.parse(location), returnsNormally);
    expect(
      CrewFilter.fromQueryParams(Uri.parse(location).queryParameters).query,
      '大安 森林',
    );
  });
}
