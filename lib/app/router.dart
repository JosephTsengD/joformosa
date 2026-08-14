import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/crew_admin/presentation/admin_screen.dart';
import '../features/crew_admin/presentation/new_session_screen.dart';
import '../features/crew_admin/presentation/register_crew_screen.dart';
import '../features/crew_detail/presentation/detail_screen.dart';
import '../features/crew_discovery/presentation/discovery_screen.dart';
import '../features/favorites/favorites_screen.dart';

/// 路由表直接對應原站的 URL 結構，讓 Web 網址正確、可分享、可 SEO，
/// 且 App 端透過 Universal Links / App Links 開啟同一組路徑。
///
/// 深連結設定（三平台一致）：
///   Web      → 天然支援
///   iOS      → ios/Runner/Runner.entitlements + /.well-known/apple-app-site-association
///   Android  → AndroidManifest intent-filter + /.well-known/assetlinks.json
final router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext _, GoRouterState __) => const DiscoveryScreen(),
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
