import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/primitives.dart';
import '../domain/entities.dart';

Color sportColor(Sport s, AppColors c) => switch (s) {
      Sport.run => c.sportRun,
      Sport.ride => c.sportRide,
      Sport.hyrox => c.sportHyrox,
      Sport.other => c.sportOther,
    };

IconData sportIcon(Sport s) => switch (s) {
      Sport.run => Icons.directions_run_rounded,
      Sport.ride => Icons.pedal_bike_rounded,
      Sport.hyrox => Icons.fitness_center_rounded,
      Sport.other => Icons.sports_rounded,
    };

class CrewCard extends StatelessWidget {
  const CrewCard({
    required this.crew,
    required this.now,
    required this.strings,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    super.key,
  });

  final Crew crew;
  final DateTime now;
  final Strings strings;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sc = sportColor(crew.sport, c);
    final tf = TimeFormatter(strings);
    final next = crew.nextSession;
    final isToday = next != null &&
        next.startsAt.year == now.year &&
        next.startsAt.month == now.month &&
        next.startsAt.day == now.day;

    // 語意標籤：讓 TalkBack 一次唸完整資訊，而不是逐個 widget 唸
    final semantic = StringBuffer()
      ..write(crew.name)
      ..write('，${crew.city.zh}')
      ..write('${sportLabel(crew.sport, strings)}社團');
    if (next != null) {
      semantic.write('，下一場 ${tf.relative(next.startsAt, now)}');
    }
    semantic.write('，活躍度 ${crew.activityScore} 分');

    return Semantics(
      container: true,
      button: true,
      label: semantic.toString(),
      // 不用 ExcludeSemantics：那會連收藏鈕一起蓋掉，讓螢幕閱讀器使用者
      // 無法收藏。改為卡片給整體語意，收藏鈕保留自己的語意。
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: InkWell(
          onTap: onTap,
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onToggleFavorite();
          },
          borderRadius: BorderRadius.circular(Radii.lg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: c.borderSubtle),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 左側運動色條：跨畫面一致，讓使用者建立顏色記憶
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: sc,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(Radii.lg),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.lg - 2,
                        Space.md + 2,
                        Space.md,
                        Space.md + 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _topRow(c, sc),
                          const SizedBox(height: Space.sm),
                          _titleRow(c),
                          if (next != null) ...<Widget>[
                            const SizedBox(height: Space.sm + 2),
                            _nextSessionRow(c, tf, next, isToday),
                          ] else ...<Widget>[
                            const SizedBox(height: Space.sm + 2),
                            Text(
                              strings.noSessions,
                              style: AppText.caption.copyWith(color: c.textTertiary),
                            ),
                          ],
                          if (crew.styles.isNotEmpty) ...<Widget>[
                            const SizedBox(height: Space.md),
                            _styleRow(c),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topRow(AppColors c, Color sc) => Row(
        children: <Widget>[
          TagChip(
            label: crew.city.code,
            color: c.textSecondary,
            background: c.surfaceSunken,
            dense: true,
            uppercase: true,
          ),
          const SizedBox(width: Space.xs + 2),
          if (crew.isNewAt(now)) ...<Widget>[
            TagChip(
              label: 'NEW',
              color: c.textOnAccent,
              background: c.accentPrimary,
              dense: true,
              uppercase: true,
            ),
            const SizedBox(width: Space.xs + 2),
          ],
          Icon(sportIcon(crew.sport), size: 13, color: sc),
          const SizedBox(width: Space.xs),
          Text(
            sportLabelEn(crew.sport),
            style: AppText.label.copyWith(color: sc),
          ),
          const Spacer(),
          ScoreChip(score: crew.activityScore),
        ],
      );

  Widget _titleRow(AppColors c) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              crew.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // 髒資料：60 字中文名稱
              style: AppText.subtitle.copyWith(color: c.textPrimary),
            ),
          ),
          const SizedBox(width: Space.sm),
          Semantics(
            button: true,
            label: isFavorite ? strings.saved : strings.save,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleFavorite,
              child: Padding(
                padding: const EdgeInsets.only(left: Space.xs, bottom: Space.xs),
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 19,
                  color: isFavorite ? c.accentPrimary : c.textTertiary,
                ),
              ),
            ),
          ),
        ],
      );

  Widget _nextSessionRow(AppColors c, TimeFormatter tf, Session next, bool isToday) =>
      Row(
        children: <Widget>[
          Icon(
            isToday ? Icons.bolt_rounded : Icons.schedule_rounded,
            size: 14,
            color: isToday ? c.accentPrimary : c.textSecondary,
          ),
          const SizedBox(width: Space.xs + 2),
          Flexible(
            child: Text(
              '${tf.relative(next.startsAt, now)} · ${next.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                color: isToday ? c.accentPrimary : c.textSecondary,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      );

  Widget _styleRow(AppColors c) => Wrap(
        spacing: Space.xs + 2,
        runSpacing: Space.xs,
        children: crew.styles
            .take(3)
            .map((StyleTag t) => Text(
                  '#${t.zh}',
                  style: AppText.micro.copyWith(color: c.textTertiary),
                ))
            .toList(),
      );
}
