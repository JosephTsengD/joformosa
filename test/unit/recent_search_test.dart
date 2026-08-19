// @spec T-070/Scenario-RecentSearches
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/features/crew_discovery/data/recent_search_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late RecentSearchStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = RecentSearchStore(await SharedPreferences.getInstance());
  });

  test('最新的搜尋排在最前面', () async {
    await store.add('夜跑');
    await store.add('河濱');
    await store.add('HYROX');

    expect(store.load(), <String>['HYROX', '河濱', '夜跑']);
  });

  test('重複的關鍵字只保留一筆，並移到最前面', () async {
    await store.add('夜跑');
    await store.add('河濱');
    await store.add('夜跑');

    // 直覺寫法 list.insert(0, q) 會在這裡產生兩個「夜跑」
    expect(store.load(), <String>['夜跑', '河濱']);
    expect(store.load().where((String e) => e == '夜跑'), hasLength(1));
  });

  test('大小寫不同視為同一筆', () async {
    await store.add('hyrox');
    await store.add('HYROX');

    expect(store.load(), hasLength(1));
    expect(store.load().first, 'HYROX');
  });

  test('上限 8 筆，超過時移除最舊的', () async {
    for (var i = 1; i <= 10; i++) {
      await store.add('關鍵字$i');
    }

    final list = store.load();
    expect(list, hasLength(RecentSearchStore.maxEntries));
    expect(list.first, '關鍵字10');
    expect(list.contains('關鍵字1'), isFalse);
    expect(list.contains('關鍵字2'), isFalse);
    expect(list.contains('關鍵字3'), isTrue);
  });

  test('空白或全空格不會被記錄', () async {
    await store.add('');
    await store.add('   ');
    expect(store.load(), isEmpty);
  });

  test('前後空白會被去除', () async {
    await store.add('  夜跑  ');
    expect(store.load(), <String>['夜跑']);
  });

  test('可移除單筆與全部清除', () async {
    await store.add('夜跑');
    await store.add('河濱');

    await store.remove('夜跑');
    expect(store.load(), <String>['河濱']);

    await store.clear();
    expect(store.load(), isEmpty);
  });
}
