import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primitives.dart';
import '../../crew_detail/presentation/session_tile.dart';
import '../../crew_discovery/domain/entities.dart';
import '../../crew_discovery/presentation/crew_card.dart';
import 'admin_controller.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(stringsProvider);
    final state = ref.watch(adminProvider);
    final now = ref.watch(clockProvider).now();

    return Scaffold(
      backgroundColor: c.surfaceSunken,
      appBar: AppBar(
        title: Text(s.adminTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      floatingActionButton: state is AdminHasCrew
          ? FloatingActionButton.extended(
              backgroundColor: c.accentPrimary,
              foregroundColor: c.textOnAccent,
              onPressed: () => context.go('/admin/session/new'),
              icon: const Icon(Icons.add_rounded),
              label: Text(s.adminNewSession, style: AppText.bodyStrong),
            )
          : null,
      body: switch (state) {
        AdminLoading() => const Center(child: CircularProgressIndicator()),
        AdminNoCrew() => EmptyStateView(
            icon: Icons.groups_outlined,
            title: s.adminNoCrewYet,
            hint: s.adminNoCrewHint,
            actionLabel: s.adminSubmitCrew,
            onAction: () => context.go('/admin/register'),
          ),
        AdminError(:final failure) => EmptyStateView(
            icon: Icons.error_outline_rounded,
            title: s.errorOf(failure.messageKey),
            hint: s.emptyNoResultHint,
            actionLabel: s.retry,
            onAction: () => ref.read(adminProvider.notifier).load(),
          ),
        AdminHasCrew(:final crew, :final detail) =>
          _dashboard(context, ref, s, crew, detail, now),
      },
    );
  }

  Widget _dashboard(
    BuildContext context,
    WidgetRef ref,
    Strings s,
    Crew crew,
    CrewDetail? detail,
    DateTime now,
  ) {
    final c = context.colors;
    final upcoming = detail?.upcoming(now) ?? const <Session>[];
    final thisMonth = (detail?.sessions ?? const <Session>[])
        .where(
            (Session x) => x.startsAt.month == now.month && x.startsAt.year == now.year)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 96),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(sportIcon(crew.sport), size: 17, color: sportColor(crew.sport, c)),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      crew.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.subtitle.copyWith(color: c.textPrimary),
                    ),
                  ),
                  TagChip(label: crew.city.code, uppercase: true, dense: true),
                ],
              ),
              const SizedBox(height: Space.lg),
              Row(
                children: <Widget>[
                  _stat(c, '$thisMonth', '本月場次'),
                  _divider(c),
                  _stat(c, '${upcoming.length}', '待舉行'),
                  _divider(c),
                  _stat(c, '${crew.activityScore}', s.scoreLabel, accent: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        // 送出不等於發布。使用者最怕的是「我送出了但什麼都沒發生」，
        // 所以審核狀態要放在最顯眼的位置，而不是讓他自己猜。
        if (crew.activityScore == 0 && upcoming.isEmpty)
          DisclaimerNote(text: s.statusPendingHint),
        const SizedBox(height: Space.sm),
        // 團長端最重要的提示：入駐義務。放在最顯眼處而非隱藏在條款裡。
        DisclaimerNote(text: s.adminNoCrewHint),
        const SizedBox(height: Space.xl),
        Text(s.upcoming, style: AppText.title.copyWith(color: c.textPrimary)),
        const SizedBox(height: Space.md),
        if (upcoming.isEmpty)
          Container(
            padding: const EdgeInsets.all(Space.xl),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Center(
              child: Text(
                s.noSessions,
                style: AppText.body.copyWith(color: c.textTertiary),
              ),
            ),
          )
        else
          ...upcoming.map(
            (Session x) => SessionTile(session: x, now: now, strings: s),
          ),
      ],
    );
  }

  Widget _stat(AppColors c, String value, String label, {bool accent = false}) =>
      Expanded(
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: AppText.numeric.copyWith(
                fontSize: 22,
                color: accent ? c.accentPrimary : c.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppText.micro.copyWith(color: c.textTertiary)),
          ],
        ),
      );

  Widget _divider(AppColors c) => Container(width: 1, height: 30, color: c.borderSubtle);
}
