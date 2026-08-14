import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/config/app_config.dart';
import '../core/l10n/strings.dart';
import '../core/utils/clock.dart';
import '../features/auth/data/fake_auth_repository.dart';
import '../features/auth/data/supabase_auth_repository.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/crew_discovery/data/fake_crew_repository.dart';
import '../features/crew_discovery/data/local_draft_store.dart';
import '../features/crew_discovery/data/resilient_crew_repository.dart';
import '../features/crew_discovery/data/supabase_crew_repository.dart';
import '../features/crew_discovery/domain/crew_repository.dart';
import '../features/crew_discovery/presentation/crew_list_controller.dart';
import '../features/crew_discovery/presentation/crew_list_state.dart';
import '../features/favorites/favorites_controller.dart';
import '../features/favorites/favorites_repository.dart';

/// DI 圖。Riverpod 的 provider 圖等同 Hilt 的 component graph——
/// 編譯期解析、無反射，心智模型與 Android 幾乎一比一。

final clockProvider = Provider<Clock>((Ref ref) => const SystemClock());

final localeProvider = StateProvider<String>((Ref ref) => 'zh-Hant');

final stringsProvider = Provider<Strings>(
  (Ref ref) => Strings(ref.watch(localeProvider)),
);

final themeModeProvider = StateProvider<ThemeMode>((Ref ref) => ThemeMode.system);

final localDraftStoreProvider = Provider<LocalDraftStore>(
  (Ref ref) => LocalDraftStore(ref.watch(sharedPrefsProvider)),
);

/// 示範模式的 repository。
///
/// 帶上 LocalDraftStore 之後，使用者送出的社團與活動會存在瀏覽器本地，
/// 重新整理仍在，且每個訪客互相隔離——GitHub Pages 上不需要任何後端
/// 就能提供完整可寫的體驗。詳見 docs/DEPLOY.md。
final fakeCrewRepositoryProvider = Provider<FakeCrewRepository>(
  (Ref ref) => FakeCrewRepository(
    ref.watch(clockProvider),
    store: ref.watch(localDraftStoreProvider),
  ),
);

/// 後端是否處於降級狀態（連不上 Supabase，正在顯示本地示範資料）
final backendDegradedProvider = StateProvider<bool>((Ref ref) => false);

/// 真實後端。設定齊全時才建立。
final supabaseCrewRepositoryProvider = Provider<SupabaseCrewRepository>(
  (Ref ref) => SupabaseCrewRepository(
    sb.Supabase.instance.client,
    ref.watch(clockProvider),
  ),
);

/// App 實際使用的 repository。
///
/// · 設定齊全 → 真實 Supabase，並包一層降級（後端掛掉時讀取退回本地資料）
/// · 設定不全 → 純本地合成資料，讓 `flutter run` 零設定即可執行
///
/// 兩條路徑都滿足同一個 CrewRepository 契約，上層完全不需要知道差別。
final crewRepositoryProvider = Provider<CrewRepository>((Ref ref) {
  if (!AppConfig.hasSupabase) return ref.watch(fakeCrewRepositoryProvider);

  return ResilientCrewRepository(
    primary: ref.watch(supabaseCrewRepositoryProvider),
    fallback: ref.watch(fakeCrewRepositoryProvider),
    onDegraded: ({required bool degraded}) {
      ref.read(backendDegradedProvider.notifier).state = degraded;
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  if (!AppConfig.hasSupabase) return FakeAuthRepository();
  return SupabaseAuthRepository(sb.Supabase.instance.client.auth);
});

final authStateProvider = StreamProvider<AppUser?>(
  (Ref ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserProvider = Provider<AppUser?>(
  (Ref ref) => ref.watch(authStateProvider).valueOrNull,
);

/// 在 main() 中以 overrideWithValue 注入實體
final sharedPrefsProvider = Provider<SharedPreferences>(
  (Ref ref) => throw UnimplementedError('overridden in main()'),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (Ref ref) => FavoritesRepository(ref.watch(sharedPrefsProvider)),
);

final favoritesProvider = StateNotifierProvider<FavoritesController, Set<String>>(
  (Ref ref) => FavoritesController(ref.watch(favoritesRepositoryProvider)),
);

/// 示範橫幅是否顯示。關閉狀態記在本地，訪客不會每次進來都被打擾。
class DemoBannerController extends StateNotifier<bool> {
  DemoBannerController(this._prefs) : super(!(_prefs.getBool(_key) ?? false));

  final SharedPreferences _prefs;
  static const _key = 'demo.banner.dismissed';

  Future<void> dismiss() async {
    state = false;
    await _prefs.setBool(_key, true);
  }

  Future<void> restore() async {
    state = true;
    await _prefs.remove(_key);
  }
}

final demoBannerVisibleProvider = StateNotifierProvider<DemoBannerController, bool>(
  (Ref ref) => DemoBannerController(ref.watch(sharedPrefsProvider)),
);

final crewListProvider = StateNotifierProvider<CrewListController, CrewListState>(
  (Ref ref) => CrewListController(ref.watch(crewRepositoryProvider)),
);
