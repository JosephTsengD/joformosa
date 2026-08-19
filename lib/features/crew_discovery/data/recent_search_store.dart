import 'package:shared_preferences/shared_preferences.dart';

/// 最近搜尋紀錄。
///
/// 三條規則寫在這裡而非 UI，因為它們是純資料邏輯，必須可單獨測試：
/// 1. 最新的在最前面
/// 2. 重複的關鍵字只保留一筆（重新搜尋會把它移到最前，不是新增第二筆）
/// 3. 上限 8 筆，超過時移除最舊的
///
/// 第 2 條最容易寫錯：直覺會寫成 `list.insert(0, q)`，
/// 結果使用者搜三次「夜跑」就看到三個「夜跑」。
class RecentSearchStore {
  RecentSearchStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'search.recent.v1';
  static const maxEntries = 8;

  List<String> load() => _prefs.getStringList(_key) ?? const <String>[];

  Future<List<String>> add(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return load();

    final next = <String>[query];
    for (final String existing in load()) {
      // 大小寫不同視為同一筆（搜尋本身也不分大小寫）
      if (existing.toLowerCase() == query.toLowerCase()) continue;
      next.add(existing);
    }

    final capped = next.take(maxEntries).toList();
    await _prefs.setStringList(_key, capped);
    return capped;
  }

  Future<List<String>> remove(String query) async {
    final next = load().where((String e) => e != query).toList();
    await _prefs.setStringList(_key, next);
    return next;
  }

  Future<void> clear() async => _prefs.remove(_key);
}
