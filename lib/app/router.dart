import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/crew_admin/presentation/admin_screen.dart';
import '../features/crew_admin/presentation/new_session_screen.dart';
import '../features/crew_admin/presentation/register_crew_screen.dart';
import '../features/crew_detail/presentation/detail_screen.dart';
import '../features/crew_discovery/presentation/discovery_screen.dart';
import '../features/crew_discovery/domain/entities.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/moderation/presentation/moderation_screen.dart';

/// 路由表直接對應原站的 URL 結構，讓 Web 網址正確、可分享、可 SEO，
/// 且 App 端透過 Universal Links / App Links 開啟同一組路徑。
///
/// 深連結設定（三平台一致）：
///   Web      → 天然支援
///   iOS      → ios/Runner/Runner.entitlements + /.well-known/apple-app-site-association
///   Android  → AndroidManifest intent-filter + /.well-known/assetlinks.json
GoRouter _createRouter() => GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext _, GoRouterState state) => DiscoveryScreen(
            // 從網址還原篩選與搜尋，讓結果可分享（T-070 SearchUrlSync）
            initialFilter: CrewFilter.fromQueryParams(state.uri.queryParameters),
          ),
        ),
        GoRoute(
          path: '/crews/:slug',
          builder: (BuildContext _, GoRouterState state) =>
              CrewDetailScreen(slug: state.pathParameters['slug']!),
        ),
        GoRoute(
          path: '/favorites',
          builder: (BuildContext _, GoRouterState __) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/me',
          builder: (BuildContext _, GoRouterState __) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (BuildContext _, GoRouterState __) => const SignInScreen(),
        ),
        GoRoute(
          // 路由本身不做權限判斷——畫面自己會顯示 Forbidden。
          // 在路由層 redirect 看起來更「乾淨」，但那需要在導覽前同步知道身分，
          // 而身分是非同步取得的，會造成閃爍或誤導向。
          path: '/moderation',
          builder: (BuildContext _, GoRouterState __) => const ModerationScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (BuildContext _, GoRouterState __) => const AdminScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'register',
              builder: (BuildContext _, GoRouterState __) => const RegisterCrewScreen(),
            ),
            GoRoute(
              path: 'session/new',
              builder: (BuildContext _, GoRouterState __) => const NewSessionScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
        body: Center(child: Text('404  ${state.uri}')),
      ),
    );

/// Router 由 provider 提供，**不是**頂層單例。
///
/// 頂層 `final router = GoRouter(...)` 看起來無害，但它是**全域可變狀態**：
/// 目前位置存在裡面。後果是同一個 process 內的所有 App 實例共用導覽歷史——
/// 在測試中就是「單獨跑會過、一起跑會失敗」，而且失敗與否取決於執行順序。
///
/// 改成 provider 之後，每個 ProviderScope 都有自己的 router，
/// 測試之間完全隔離。這不是為了測試而做的妥協，
/// 而是「全域可變狀態」本來就該避免。
final routerProvider = Provider<GoRouter>((Ref ref) {
  final router = _createRouter();
  ref.onDispose(router.dispose);
  return router;
});
