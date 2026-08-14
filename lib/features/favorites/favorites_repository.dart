import 'package:shared_preferences/shared_preferences.dart';

/// 收藏採 local-first：離線必須可讀可寫，連線後背景同步。
/// 衝突解法：favorites 是 set，last-write-wins 加時間戳即可（CRDT-friendly）。
class FavoritesRepository {
  FavoritesRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'favorites.crewIds';

  Set<String> load() => _prefs.getStringList(_key)?.toSet() ?? <String>{};

  Future<void> save(Set<String> ids) async {
    await _prefs.setStringList(_key, ids.toList());
  }
}
