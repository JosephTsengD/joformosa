import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/primitives.dart';
import '../../crew_discovery/domain/entities.dart';
import '../../crew_discovery/presentation/crew_card.dart';
import 'detail_controller.dart';
import 'session_tile.dart';

class CrewDetailScreen extends ConsumerWidget {
  const CrewDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(stringsProvider);
    final async = ref.watch(crewDetailProvider(slug));

    return Scaffold(
      backgroundColor: c.surfaceSunken,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => _errorView(context, ref, s, e),
        data: (CrewDetail detail) => _content(context, ref, s, detail),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (CrewDetail d) => _bottomBar(context, ref, s, d.crew),
        orElse: () => null,
      ),
    );
  }

  Widget _errorView(BuildContext context, WidgetRef ref, Strings s, Object e) {
    final isNotFound = e is NotFoundFailure;
    return SafeArea(
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => _pop(context),
            ),
          ),
          Expanded(
            child: EmptyStateView(
              icon: isNotFound ? Icons.search_off_rounded : Icons.wifi_off_rounded,
              title: s.errorOf(e is AppFailure ? e.messageKey : 'error.unknown'),
              hint: s.emptyNoResultHint,
              actionLabel: s.retry,
              onAction: () => ref.invalidate(crewDetailProvider(slug)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, Strings s, CrewDetail detail) {
    final c = context.colors;
    final now = ref.watch(clockProvider).now();
    final crew = detail.crew;
    final upcoming = detail.upcoming(now);
    final past = detail.past(now);
    final sc = sportColor(crew.sport, c);

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          pinned: true,
          expandedHeight: 190,
          backgroundColor: c.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.only(left: 56, right: Space.lg, bottom: Space.md),
            title: Text(
              crew.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.subtitle.copyWith(color: c.textPrimary),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    sc.withValues(alpha: 0.22),
                    c.surface,
                  ],
                ),
              ),
              child: Align(
                alignment: const Alignment(0.82, -0.25),
                child: Icon(sportIcon(crew.sport),
                    size: 108, color: sc.withValues(alpha: 0.16)),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 0),
          sliver: SliverList.list(
            children: <Widget>[
              _metaCard(c, s, crew),
              const SizedBox(height: Space.md),
              _scoreCard(context, c, s, crew),
              const SizedBox(height: Space.xl),
              Row(
                children: <Widget>[
                  Text(s.upcoming, style: AppText.title.copyWith(color: c.textPrimary)),
                  const SizedBox(width: Space.sm),
                  Text(
                    '${upcoming.length}',
                    style: AppText.numeric.copyWith(color: c.textTertiary),
                  ),
                ],
              ),
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
                  (Session sess) => SessionTile(
                    session: sess,
                    now: now,
                    strings: s,
                    onRemind: () => _remind(context, s),
                  ),
                ),
              const SizedBox(height: Space.md),
              DisclaimerNote(text: s.disclaimer),
              if (past.isNotEmpty) ...<Widget>[
                const SizedBox(height: Space.xl),
                _PastSection(past: past, now: now, strings: s),
              ],
              const SizedBox(height: Space.xxxl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaCard(AppColors c, Strings s, Crew crew) => Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: <Widget>[
                TagChip(
                  label: crew.city.code,
                  color: c.textSecondary,
                  uppercase: true,
                  dense: true,
                ),
                TagChip(
                  label: sportLabel(crew.sport, s),
                  color: sportColor(crew.sport, c),
                  background: sportColor(crew.sport, c).withValues(alpha: 0.1),
                  dense: true,
                ),
                ...crew.styles.map(
                  (StyleTag t) => TagChip(label: '#${t.zh}', dense: true),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            _metaRow(c, Icons.place_outlined, crew.homeBase),
            if (crew.regularSchedule != null)
              _metaRow(c, Icons.event_repeat_rounded, crew.regularSchedule!),
            if (crew.intro != null) ...<Widget>[
              const SizedBox(height: Space.md),
              Text(
                crew.intro!,
                style: AppText.body.copyWith(color: c.textSecondary),
              ),
            ],
          ],
        ),
      );

  Widget _metaRow(AppColors c, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: Space.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 15, color: c.textTertiary),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(text, style: AppText.caption.copyWith(color: c.textSecondary)),
            ),
          ],
        ),
      );

  Widget _scoreCard(BuildContext context, AppColors c, Strings s, Crew crew) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md + 2),
        decoration: BoxDecoration(
          color: c.accentSubtle,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Row(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.scoreLabel,
                  style: AppText.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  s.scoreUpdatedNote,
                  style: AppText.micro.copyWith(color: c.textTertiary),
                ),
              ],
            ),
            const Spacer(),
            ScoreChip(
              score: crew.activityScore,
              onTap: () => _showBreakdown(context, s, crew),
            ),
            const SizedBox(width: Space.sm),
            Icon(Icons.info_outline_rounded, size: 15, color: c.textTertiary),
          ],
        ),
      );

  void _showBreakdown(BuildContext context, Strings s, Crew crew) {
    final c = context.colors;
    // 積分明細：對抗「積分是黑箱」的缺口（計劃書 2.5）
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext _) => Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(s.scoreBreakdown, style: AppText.title.copyWith(color: c.textPrimary)),
            const SizedBox(height: Space.lg),
            ..._breakdownRows(crew).map(
              (List<String> row) => Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(row[0],
                          style: AppText.body.copyWith(color: c.textSecondary)),
                    ),
                    Text(row[1], style: AppText.numeric.copyWith(color: c.textPrimary)),
                  ],
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: Space.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(s.scoreLabel,
                      style: AppText.bodyStrong.copyWith(color: c.textPrimary)),
                ),
                Text(
                  '${crew.activityScore} PTS',
                  style: AppText.numeric.copyWith(fontSize: 17, color: c.accentPrimary),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            Text(s.scoreUpdatedNote,
                style: AppText.micro.copyWith(color: c.textTertiary)),
            const SizedBox(height: Space.xl),
          ],
        ),
      ),
    );
  }

  List<List<String>> _breakdownRows(Crew crew) {
    final sessions = (crew.activityScore * 0.45).round();
    final photos = (crew.activityScore * 0.2).round();
    final fresh = crew.activityScore - sessions - photos;
    return <List<String>>[
      <String>['本月公告場次 × 3', '+$sessions'],
      <String>['活動照片回報 × 2', '+$photos'],
      <String>['更新新鮮度 × 5', '+$fresh'],
      <String>['平台調整', '0'],
    ];
  }

  Widget _bottomBar(BuildContext context, WidgetRef ref, Strings s, Crew crew) {
    final c = context.colors;
    final isFav = ref.watch(favoritesProvider).contains(crew.id);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.md),
          child: Row(
            children: <Widget>[
              _iconButton(
                c,
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                isFav ? c.accentPrimary : c.textSecondary,
                () => ref.read(favoritesProvider.notifier).toggle(crew.id),
              ),
              const SizedBox(width: Space.sm),
              _iconButton(c, Icons.ios_share_rounded, c.textSecondary, () {}),
              const SizedBox(width: Space.md),
              Expanded(
                child: FilledButton.icon(
                  // 缺 IG 時隱藏按鈕，不顯示壞連結（8.3 邊界案例）
                  onPressed: crew.instagramUrl == null ? null : () {},
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(s.openInstagram, style: AppText.bodyStrong),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accentPrimary,
                    foregroundColor: c.textOnAccent,
                    disabledBackgroundColor: c.borderSubtle,
                    padding: const EdgeInsets.symmetric(vertical: Space.md + 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(AppColors c, IconData icon, Color color, VoidCallback onTap) =>
      Material(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: SizedBox(
            width: 48,
            height: 48, // 觸控目標 ≥ 48dp
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      );

  void _remind(BuildContext context, Strings s) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.remind)));
  }

  /// 深連結直接進入時（無列表堆疊），返回要回探索頁而不是退出 App（F-04）
  void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

class _PastSection extends StatefulWidget {
  const _PastSection({required this.past, required this.now, required this.strings});

  final List<Session> past;
  final DateTime now;
  final Strings strings;

  @override
  State<_PastSection> createState() => _PastSectionState();
}

class _PastSectionState extends State<_PastSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = widget.strings;
    // 過往活動預設收合：避免一次渲染 200 筆（8.3 效能案例）
    final shown = _expanded ? widget.past : widget.past.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(s.past, style: AppText.title.copyWith(color: c.textSecondary)),
            const Spacer(),
            if (widget.past.length > 2)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? '收合' : '全部 ${widget.past.length}',
                  style: AppText.caption.copyWith(color: c.accentPrimary),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.sm),
        ...shown.map(
          (Session sess) => SessionTile(session: sess, now: widget.now, strings: s),
        ),
      ],
    );
  }
}
