import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/primitives.dart';
import '../../crew_discovery/domain/entities.dart';
import '../../crew_discovery/presentation/crew_card.dart';
import '../domain/moderation_repository.dart';
import 'moderation_controller.dart';

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(stringsProvider);
    final state = ref.watch(moderationProvider);

    return Scaffold(
      backgroundColor: c.surfaceSunken,
      appBar: AppBar(
        title: Text(s.moderationTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: switch (state) {
        ModerationLoading() => const Center(child: CircularProgressIndicator()),
        ModerationForbidden() => EmptyStateView(
            icon: Icons.lock_outline_rounded,
            title: s.moderationForbidden,
            hint: s.moderationForbiddenHint,
            actionLabel: s.navDiscover,
            onAction: () => context.go('/'),
          ),
        ModerationError(:final failure) => EmptyStateView(
            icon: Icons.error_outline_rounded,
            title: s.errorOf(failure.messageKey),
            hint: s.emptyNoResultHint,
            actionLabel: s.retry,
            onAction: () => ref.read(moderationProvider.notifier).load(),
          ),
        ModerationReady(:final pending, :final log) =>
          _queue(context, ref, s, pending, log),
      },
    );
  }

  Widget _queue(
    BuildContext context,
    WidgetRef ref,
    Strings s,
    List<Crew> pending,
    List<ModerationEntry> log,
  ) {
    final c = context.colors;
    final now = ref.watch(clockProvider).now();

    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              s.moderationPendingCount(pending.length),
              style: AppText.title.copyWith(color: c.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        if (pending.isEmpty)
          Container(
            padding: const EdgeInsets.all(Space.xl),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  s.moderationEmpty,
                  style: AppText.bodyStrong.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  s.moderationEmptyHint,
                  textAlign: TextAlign.center,
                  style: AppText.micro.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          )
        else
          ...pending.map((Crew crew) => _pendingCard(context, ref, s, crew, now)),
        const SizedBox(height: Space.xxl),
        Text(s.moderationAudit, style: AppText.title.copyWith(color: c.textPrimary)),
        const SizedBox(height: Space.md),
        if (log.isEmpty)
          Text(
            s.moderationAuditEmpty,
            style: AppText.body.copyWith(color: c.textTertiary),
          )
        else
          ...log.map((ModerationEntry e) => _auditRow(context, s, e)),
      ],
    );
  }

  Widget _pendingCard(
    BuildContext context,
    WidgetRef ref,
    Strings s,
    Crew crew,
    DateTime now,
  ) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      sportIcon(crew.sport),
                      size: 16,
                      color: sportColor(crew.sport, c),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        crew.name,
                        maxLines: 2,
                        style: AppText.subtitle.copyWith(color: c.textPrimary),
                      ),
                    ),
                    TagChip(label: crew.city.code, uppercase: true, dense: true),
                  ],
                ),
                const SizedBox(height: Space.md),
                _row(c, Icons.place_outlined, crew.homeBase),
                if (crew.intro != null) ...<Widget>[
                  const SizedBox(height: Space.sm),
                  Text(
                    crew.intro!,
                    style: AppText.caption.copyWith(color: c.textSecondary),
                  ),
                ],
                if (crew.instagramUrl != null) ...<Widget>[
                  const SizedBox(height: Space.sm),
                  _row(c, Icons.link_rounded, crew.instagramUrl!),
                ],
              ],
            ),
          ),
          Container(height: 1, color: c.borderSubtle),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _promptReject(context, ref, s, crew.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.danger,
                      side: BorderSide(color: c.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: Space.md),
                    ),
                    child: Text(s.moderationReject, style: AppText.bodyStrong),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => _approve(context, ref, s, crew.id),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.success,
                      foregroundColor: c.textOnAccent,
                      padding: const EdgeInsets.symmetric(vertical: Space.md),
                    ),
                    child: Text(s.moderationApprove, style: AppText.bodyStrong),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppColors c, IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 14, color: c.textTertiary),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              text,
              style: AppText.caption.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      );

  Widget _auditRow(BuildContext context, Strings s, ModerationEntry e) {
    final c = context.colors;
    final approved = e.action == ModerationAction.approve;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            approved ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 15,
            color: approved ? c.success : c.danger,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${approved ? s.moderationApprove : s.moderationReject} · ${e.actorId}',
                  style: AppText.caption.copyWith(color: c.textPrimary),
                ),
                if (e.reason != null)
                  Text(
                    e.reason!,
                    style: AppText.micro.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            '${TimeFormatter.md(e.at)} ${TimeFormatter.hhmm(e.at)}',
            style: AppText.micro.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    Strings s,
    String crewId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final r = await ref.read(moderationProvider.notifier).approve(crewId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          switch (r) {
            Ok<void>() => s.moderationApproved,
            Err<void>(:final failure) => s.errorOf(failure.messageKey),
          },
        ),
      ),
    );
  }

  Future<void> _promptReject(
    BuildContext context,
    WidgetRef ref,
    Strings s,
    String crewId,
  ) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final reason = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setDialogState) {
          final empty = controller.text.trim().isEmpty;
          return AlertDialog(
            title: Text(s.moderationReason, style: AppText.subtitle),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              onChanged: (_) => setDialogState(() {}),
              decoration: InputDecoration(
                hintText: s.moderationReasonRequired,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel),
              ),
              TextButton(
                // 空理由時直接停用送出。使用者不必先按了才知道不行。
                onPressed:
                    empty ? null : () => Navigator.pop(ctx, controller.text.trim()),
                child: Text(s.moderationReject),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();

    if (reason == null) return;
    final r = await ref.read(moderationProvider.notifier).reject(crewId, reason);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          switch (r) {
            Ok<void>() => s.moderationRejected,
            Err<void>(:final failure) => s.errorOf(failure.messageKey),
          },
        ),
      ),
    );
  }
}
