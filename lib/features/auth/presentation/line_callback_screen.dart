import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/primitives.dart';
import '../domain/auth_models.dart';

/// LINE 導回後的中繼畫面。
///
/// 使用者只會看到它一到兩秒，但這一兩秒必須有東西——
/// 交換 token 需要一次網路往返，空白畫面會讓人以為登入失敗又點一次。
class LineCallbackScreen extends ConsumerStatefulWidget {
  const LineCallbackScreen({required this.callbackUri, super.key});

  final Uri callbackUri;

  @override
  ConsumerState<LineCallbackScreen> createState() => _LineCallbackScreenState();
}

class _LineCallbackScreenState extends ConsumerState<LineCallbackScreen> {
  String? _errorReason;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle());
  }

  Future<void> _handle() async {
    final result =
        await ref.read(authRepositoryProvider).completeExternalSignIn(widget.callbackUri);
    if (!mounted) return;

    switch (result) {
      case Ok<AppUser>():
        context.go('/me');
      case Err<AppUser>(:final failure):
        // 使用者自己按取消不是錯誤，直接送回首頁，不要顯示紅字
        if (failure is AuthFailure && failure.reason == 'userCancelled') {
          context.go('/');
          return;
        }
        setState(() {
          _errorReason = failure is AuthFailure ? failure.reason : 'unknown';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ref.watch(stringsProvider);

    if (_errorReason != null) {
      return Scaffold(
        backgroundColor: c.surface,
        body: SafeArea(
          child: EmptyStateView(
            icon: Icons.error_outline_rounded,
            title: s.errorAuth,
            hint: s.lineErrorHint(_errorReason!),
            actionLabel: s.retry,
            onAction: () => context.go('/sign-in'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(color: c.accentPrimary),
            const SizedBox(height: Space.xl),
            Text(
              s.lineSigningIn,
              style: AppText.body.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
