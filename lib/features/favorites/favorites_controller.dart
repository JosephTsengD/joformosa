import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'favorites_repository.dart';

/// 樂觀更新（F-07）：點擊立即變心形，不等網路；失敗則回滾。
/// rollback 必須是 apply 的**逆運算**——這裡因為是 set 的 add/remove，
/// 逆運算自然成立，這也是選用 set 的理由之一。
class FavoritesController extends StateNotifier<Set<String>> {
  FavoritesController(this._repo) : super(_repo.load());

  final FavoritesRepository _repo;

  bool contains(String id) => state.contains(id);

  /// 重置示範資料時一併清空收藏
  Future<void> clearAll() async {
    state = <String>{};
    await _repo.save(<String>{});
  }

  Future<bool> toggle(String crewId) async {
    final before = state;
    final next = Set<String>.from(state);
    final added = !next.contains(crewId);
    if (added) {
      next.add(crewId);
    } else {
      next.remove(crewId);
    }
    state = next; // ① 立即更新 UI

    try {
      await _repo.save(next); // ② 持久化
      return added;
    } catch (_) {
      state = before; // ③ 失敗回滾
      rethrow;
    }
  }
}
