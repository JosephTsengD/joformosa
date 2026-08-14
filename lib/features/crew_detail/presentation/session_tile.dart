import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/primitives.dart';
import '../../crew_discovery/domain/entities.dart';

class SessionTile extends StatelessWidget {
  const SessionTile({
    required this.session,
    required this.now,
    required this.strings,
    super.key,
    this.onRemind,
  });

  final Session session;
  final DateTime now;
  final Strings strings;
  final VoidCallback? onRemind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = session.statusAt(now);
    final isPast = status == SessionStatus.past;
    final isOngoing = status == SessionStatus.ongoing;
    final isImminent = status == SessionStatus.imminent;
    final highlight = isOngoing || isImminent;
    final tf = TimeFormatter(strings);

    return Opacity(
      opacity: isPast ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.sm + 2),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: highlight ? c.accentPrimary.withValues(alpha: 0.4) : c.borderSubtle,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _dateBlock(c, highlight),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyStrong.copyWith(color: c.textPrimary),
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        if (isOngoing)
                          TagChip(
                            label: strings.ongoing,
                            color: c.textOnAccent,
                            background: c.success,
                            dense: true,
                          )
                        else if (session.kind != SessionKind.regular)
                          TagChip(
                            label: sessionKindLabel(session.kind, strings),
                            color: c.accentPrimary,
                            background: c.accentSubtle,
                            dense: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.xs + 1),
                    Text(
                      tf.fullRange(session),
                      maxLines: 2,
                      style: AppText.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!isPast && onRemind != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: strings.remind,
                  onPressed: onRemind,
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    size: 19,
                    color: c.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateBlock(AppColors c, bool highlight) => Container(
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        decoration: BoxDecoration(
          color: highlight ? c.accentPrimary : c.surfaceSunken,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '${session.startsAt.day}',
              style: AppText.numeric.copyWith(
                fontSize: 19,
                color: highlight ? c.textOnAccent : c.textPrimary,
              ),
            ),
            Text(
              TimeFormatter.monthShort(session.startsAt),
              style: AppText.label.copyWith(
                color: highlight ? c.textOnAccent : c.textTertiary,
              ),
            ),
          ],
        ),
      );
}
