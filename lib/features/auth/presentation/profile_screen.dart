import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/auth_models.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(stringsProvider);
    final user = ref.watch(currentUserProvider);
    final favCount = ref.watch(favoritesProvider).length;

    return Scaffold(
      backgroundColor: c.surfaceSunken,
      appBar: AppBar(
        title: Text(s.navMe),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 26,
                  backgroundColor: c.accentSubtle,
                  child: Icon(
                    user == null || user.isGuest
                        ? Icons.person_outline_rounded
                        : Icons.person_rounded,
                    color: c.accentPrimary,
                  ),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user?.displayName ?? s.guestUser,
                        style: AppText.subtitle.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.provider == AuthProvider.line ? 'LINE' : s.signInBenefit,
                        maxLines: 2,
                        style: AppText.micro.copyWith(color: c.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (user == null || user.isGuest)
                  FilledButton(
                    onPressed: () => context.go('/sign-in'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accentPrimary,
                      foregroundColor: c.textOnAccent,
                    ),
                    child: Text(s.signIn, style: AppText.caption),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          _tile(context, Icons.favorite_border_rounded, s.navFavorites, '$favCount',
              () => context.go('/favorites')),
          _tile(context, Icons.groups_rounded, s.adminTitle, null,
              () => context.go('/admin')),
          _tile(
            context,
            Icons.brightness_6_rounded,
            '主題',
            null,
            () => ref.read(themeModeProvider.notifier).update(
                  (ThemeMode m) => m == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                ),
          ),
          _tile(
            context,
            Icons.translate_rounded,
            'Language',
            ref.watch(localeProvider).startsWith('zh') ? '中文' : 'EN',
            () => ref.read(localeProvider.notifier).update(
                  (String l) => l.startsWith('zh') ? 'en' : 'zh-Hant',
                ),
          ),
          const SizedBox(height: Space.lg),
          _tile(
            context,
            Icons.restart_alt_rounded,
            s.demoReset,
            null,
            () => _confirmReset(context, ref, s),
          ),
          if (user != null && !user.isGuest) ...<Widget>[
            const SizedBox(height: Space.lg),
            TextButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: Text(s.signOut, style: AppText.body.copyWith(color: c.danger)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref, Strings s) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        content: Text(s.demoResetConfirm, style: AppText.body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.demoReset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(fakeCrewRepositoryProvider).resetDemoData();
    await ref.read(favoritesProvider.notifier).clearAll();
    await ref.read(demoBannerVisibleProvider.notifier).restore();
    // 要 await：不等列表刷新完就跳提示，使用者會看到「已重置」
    // 但畫面上還是舊資料，一秒後才變——那比慢一點更糟。
    await ref.read(crewListProvider.notifier).refresh();

    messenger.showSnackBar(SnackBar(content: Text(s.demoResetDone)));
  }

  Widget _tile(BuildContext context, IconData icon, String title, String? trailing,
      VoidCallback onTap) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.borderSubtle),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 20, color: c.textSecondary),
        title: Text(title, style: AppText.body.copyWith(color: c.textPrimary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (trailing != null)
              Text(trailing, style: AppText.caption.copyWith(color: c.textTertiary)),
            const SizedBox(width: Space.xs),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
