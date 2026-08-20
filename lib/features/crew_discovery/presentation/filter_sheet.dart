import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primitives.dart';
import '../domain/entities.dart';

/// Bottom sheet 而非頂部 dropdown：主要操作放螢幕下半部，單手可達。
/// 底部固定「查看 N 個結果」提供即時預覽，減少來回試錯。
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    required this.initial,
    required this.strings,
    required this.countFor,
    super.key,
  });

  final CrewFilter initial;
  final Strings strings;
  final int Function(CrewFilter) countFor;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late CrewFilter _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = widget.strings;
    final count = widget.countFor(_draft);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, Space.md, Space.xl, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
            Row(
              children: <Widget>[
                Text(s.filterWhen,
                    style: AppText.subtitle.copyWith(color: c.textPrimary)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _draft = const CrewFilter()),
                  child: Text(
                    s.filterClear,
                    style: AppText.caption.copyWith(color: c.accentPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: TimeWindow.values
                  .map(
                    (TimeWindow w) => FilterChipButton(
                      label: switch (w) {
                        TimeWindow.any => s.whenAny,
                        TimeWindow.today => s.whenToday,
                        TimeWindow.thisWeek => s.whenThisWeek,
                        TimeWindow.weekend => s.whenWeekend,
                      },
                      selected: _draft.timeWindow == w,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(timeWindow: w),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Space.xl),
            Text(s.filterCity, style: AppText.subtitle.copyWith(color: c.textPrimary)),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: <Widget>[
                FilterChipButton(
                  label: s.sportAll,
                  selected: _draft.city == null,
                  onTap: () => setState(() => _draft = _draft.copyWith(clearCity: true)),
                ),
                ...City.all.map(
                  (City city) => FilterChipButton(
                    label: city.zh,
                    selected: _draft.city == city,
                    onTap: () => setState(() {
                      _draft = _draft.city == city
                          ? _draft.copyWith(clearCity: true)
                          : _draft.copyWith(city: city);
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.xl),
            Text(s.filterStyle, style: AppText.subtitle.copyWith(color: c.textPrimary)),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: StyleTag.all
                  .map(
                    (StyleTag t) => FilterChipButton(
                      label: t.zh,
                      selected: _draft.styles.contains(t),
                      onTap: () => setState(() {
                        final next = Set<StyleTag>.from(_draft.styles);
                        if (!next.remove(t)) next.add(t);
                        _draft = _draft.copyWith(styles: next);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Space.xl),
            Text(s.sortByScore, style: AppText.subtitle.copyWith(color: c.textPrimary)),
            const SizedBox(height: Space.md),
            Row(
              children: <Widget>[
                FilterChipButton(
                  label: s.sortByScore,
                  selected: _draft.sort == CrewSort.score,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(sort: CrewSort.score)),
                ),
                const SizedBox(width: Space.sm),
                FilterChipButton(
                  label: s.sortByNext,
                  selected: _draft.sort == CrewSort.nextSession,
                  onTap: () => setState(
                      () => _draft = _draft.copyWith(sort: CrewSort.nextSession)),
                ),
              ],
            ),
            const SizedBox(height: Space.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: count == 0 ? null : () => Navigator.of(context).pop(_draft),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accentPrimary,
                  foregroundColor: c.textOnAccent,
                  disabledBackgroundColor: c.borderSubtle,
                  padding: const EdgeInsets.symmetric(vertical: Space.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
                child: Text(
                  count == 0 ? s.emptyNoResult : s.filterResultCount(count),
                  style: AppText.bodyStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
