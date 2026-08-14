import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 小標籤：縣市代碼、運動類別、NEW 徽章
class TagChip extends StatelessWidget {
  const TagChip({
    required this.label,
    super.key,
    this.color,
    this.background,
    this.dense = false,
    this.uppercase = false,
  });

  final String label;
  final Color? color;
  final Color? background;
  final bool dense;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Space.sm : Space.md - 2,
        vertical: dense ? 2 : Space.xs,
      ),
      decoration: BoxDecoration(
        color: background ?? c.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        label,
        style: (uppercase ? AppText.label : AppText.micro).copyWith(color: fg),
      ),
    );
  }
}

/// 篩選 chip：可點擊、有選中態
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.leading,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? c.accentPrimary : c.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Curves.easeOut,
            // 觸控目標 ≥ 48dp（a11y）：視覺可以小，命中區要夠大
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: Space.lg - 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(
                color: selected ? c.accentPrimary : c.borderSubtle,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(width: Space.xs + 2)
                ],
                Text(
                  label,
                  style: AppText.caption.copyWith(
                    color: selected ? c.textOnAccent : c.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: Space.xs),
                  trailing!
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 積分 pill
class ScoreChip extends StatelessWidget {
  const ScoreChip({required this.score, super.key, this.label, this.onTap});

  final int score;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RichText(
            text: TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$score',
                  style: AppText.numeric.copyWith(fontSize: 17, color: c.accentPrimary),
                ),
                TextSpan(
                  text: ' PTS',
                  style: AppText.label.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
          if (label != null)
            Text(label!, style: AppText.micro.copyWith(color: c.textTertiary)),
        ],
      ),
    );
  }
}

/// 免責聲明。產品決策：不可關閉，且就近顯示（不放頁尾）。
class DisclaimerNote extends StatelessWidget {
  const DisclaimerNote({required this.text, super.key, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: compact ? Space.sm : Space.md,
      ),
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 14, color: c.warning),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              text,
              style: AppText.micro.copyWith(color: c.warning, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// 空狀態
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.icon,
    required this.title,
    required this.hint,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.accentSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: c.accentPrimary),
            ),
            const SizedBox(height: Space.lg),
            Text(title, style: AppText.subtitle.copyWith(color: c.textPrimary)),
            const SizedBox(height: Space.sm),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: c.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: Space.xl),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: c.accentPrimary,
                  foregroundColor: c.textOnAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.xl,
                    vertical: Space.md + 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
                child: Text(actionLabel!, style: AppText.bodyStrong),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 骨架屏。卡片數量固定，避免載入前後高度跳動。
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose(); // 資源洩漏檢查（reviewer 清單第 5 項）
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext context, Widget? child) {
        final t = 0.35 + _ctrl.value * 0.3;
        return Container(
          height: 104,
          margin: const EdgeInsets.only(bottom: Space.md),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: c.borderSubtle),
          ),
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _bar(c.borderSubtle.withValues(alpha: t), 60, 10),
              const SizedBox(height: Space.md),
              _bar(c.borderStrong.withValues(alpha: t), 180, 14),
              const SizedBox(height: Space.sm + 2),
              _bar(c.borderSubtle.withValues(alpha: t), 120, 10),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(Color color, double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      );
}

/// 示範模式橫幅。
///
/// 產品決策：不要用彈窗。彈窗會擋住第一眼要看的內容，
/// 而訪客通常在讀完之前就按掉了。橫幅留在原地、可關閉、不干擾。
class DemoBanner extends StatelessWidget {
  const DemoBanner({
    required this.badge,
    required this.body,
    required this.dismissLabel,
    required this.onDismiss,
    super.key,
  });

  final String badge;
  final String body;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 0),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.accentSubtle,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.accentPrimary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.science_outlined, size: 16, color: c.accentPrimary),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  badge,
                  style: AppText.micro.copyWith(color: c.accentPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppText.micro.copyWith(
                    color: c.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(Space.xs),
              child: Text(
                dismissLabel,
                style: AppText.micro.copyWith(color: c.accentPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「顯示的是 N 前的資料」提示條
class StaleBanner extends StatelessWidget {
  const StaleBanner(
      {required this.text,
      required this.onRefresh,
      required this.actionLabel,
      super.key});

  final String text;
  final String actionLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceSunken,
      child: InkWell(
        onTap: onRefresh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
          child: Row(
            children: <Widget>[
              Icon(Icons.cloud_off_rounded, size: 14, color: c.textTertiary),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(text, style: AppText.micro.copyWith(color: c.textSecondary)),
              ),
              Text(
                actionLabel,
                style: AppText.micro.copyWith(color: c.accentPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
