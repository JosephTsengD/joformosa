import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/result.dart';
import '../domain/auth_models.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;

  /// LINE 品牌色。這是**唯一**允許出現的品牌硬編碼色，
  /// 因為第三方品牌規範不可主題化（LINE Login button 設計指南要求）。
  static const _lineGreen = Color(0xFF06C755);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Spacer(flex: 2),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.accentPrimary,
                  borderRadius: BorderRadius.circular(Radii.lg),
                ),
                child: Icon(Icons.groups_rounded, color: c.textOnAccent, size: 34),
              ),
              const SizedBox(height: Space.xl),
              Text(s.signIn, style: AppText.display.copyWith(color: c.textPrimary)),
              const SizedBox(height: Space.sm),
              Text(
                s.signInBenefit,
                style: AppText.body.copyWith(color: c.textSecondary),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _signInWithLine,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.chat_bubble_rounded, size: 19),
                  label: Text(s.signInWithLine, style: AppText.bodyStrong),
                  style: FilledButton.styleFrom(
                    backgroundColor: _lineGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _lineGreen.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: Space.lg),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.md),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _busy ? null : _continueAsGuest,
                  child: Text(
                    s.browseAsGuest,
                    style: AppText.body.copyWith(color: c.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: Space.xl),
              Text(
                // 誠實揭露：使用者有權知道拿了什麼資料
                s.locale.startsWith('zh')
                    ? '我們只會取得你的 LINE 顯示名稱與大頭貼，不會取得好友清單，也不會代你發送訊息。'
                    : 'We only read your LINE display name and avatar.',
                style: AppText.micro.copyWith(color: c.textTertiary, height: 1.5),
              ),
              const SizedBox(height: Space.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithLine() async {
    setState(() => _busy = true);
    final repo = ref.read(authRepositoryProvider);
    // 匿名 → LINE 用 link 而非重新登入，確保本地收藏不遺失（F-07）
    final result = repo.currentUser?.isGuest ?? false
        ? await repo.linkLine()
        : await repo.signInWithLine();
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Ok<AppUser>():
        context.go('/me');
      case Err<AppUser>(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(stringsProvider).errorOf(failure.messageKey))),
        );
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _busy = true);
    await ref.read(authRepositoryProvider).signInAnonymously();
    if (!mounted) return;
    setState(() => _busy = false);
    context.go('/');
  }
}
